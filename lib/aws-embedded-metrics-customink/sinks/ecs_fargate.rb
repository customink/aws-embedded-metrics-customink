# frozen_string_literal: true

require 'tcp-client'

module Aws
  module Embedded
    module Metrics
      module Sinks
        #
        # Create a sink that will communicate to a CloudWatch Log Agent over a TCP connection.
        # This is intended to be used on ECS Fargate instances where the CloudWatch Log Agent
        # is deployed as a side-car container.
        #
        # See https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format_Generation_CloudWatch_Agent.html
        # for configuration information
        class EcsFargate
          DEFAULT_ENV_VAR_NAME = 'AWS_EMF_AGENT_ENDPOINT'
          attr_reader :queue

          #
          # Create a new Fargate sink. It will use the +AWS_EMF_AGENT_ENDPOINT+ environment variable by default to
          # connect to a CloudWatch Metric Agent side-car container.
          # This was built as a performance-critical piece of code since metrics are often a high-volume item.
          # +#accept+, which is what takes in messages to send to the CW Metric Agent, puts messages into a thread-safe
          # queue. A separate thread is then picking up from that queue and sending the messages over a persistent
          # TCP connection to the agent.
          #
          # <b>Creating a new EcsFargate sink will create a new thread and connection to the agent.</b>
          # This sink is intended to be used sparingly.
          #
          # Messages that time out or can't be sent are put back at the end of the queue.
          # If a message is enqueued and the queue is full, the message is dropped and a warning is logged.
          #
          # If you use this sink, you *MUST* call <tt>metrics.set_property("log_group_name", "<value>")</tt>.
          # The CW Agent will reject your messages if the log group name is not included.
          #
          # @param conn_str [String] A connection string, formatted like 'tcp://127.0.0.1:25888'
          # @param max_queue_size [Numeric] The number of messages to buffer in-memory.
          # @param conn_timeout_secs [Numeric] The number of seconds before timing out the connection to the agent.
          # @param write_timeout_secs [Numeric] The number of seconds to wait before timing out a write.
          # @param logger [Logger] A standard Ruby logger to propagate warnings and errors.
          #   Suggested to use Rails.logger.
          def initialize(conn_str: ENV.fetch(DEFAULT_ENV_VAR_NAME, nil),
                         max_queue_size: 10_000,
                         conn_timeout_secs: 10,
                         write_timeout_secs: 10,
                         logger: nil)
            if conn_str.nil?
              raise Sinks::Error, "Must specify a connection string or set environment variable #{DEFAULT_ENV_VAR_NAME}"
            end

            @logger = logger
            @cw_agent_uri = URI.parse(conn_str)
            if @cw_agent_uri.scheme != 'tcp' || !@cw_agent_uri.host || !@cw_agent_uri.port
              raise Sinks::Error, "Expected connection string to be in format tcp://<host>:<port>, got '#{conn_str}'"
            end

            @max_queue_size = max_queue_size
            @queue = Queue.new

            @client_opts = TCPClient::Configuration.create(
              buffered: false,
              keep_alive: true,
              connect_timeout: conn_timeout_secs,
              write_timeout: write_timeout_secs
            )

            @lock = Mutex.new
            @stop = false
            start_sender(@queue)
          end

          def log_warn(msg)
            @logger&.warn(msg)
          end

          def log_err(msg)
            @logger&.error(msg)
          end

          def accept(message)
            if @max_queue_size > -1 && @queue.length > @max_queue_size
              log_warn("ECS Fargate Sink Queue is full (#{@max_queue_size} items)! Dropping metric message.")
              return
            end

            @queue.push("#{JSON.dump(message)}\n")
          end

          #
          # Shut down the sink. By default this blocks until all messages are sent to the agent, or
          # the wait time elapses. No more messages will be accepted as soon as this is called.
          #
          # @param wait_time_seconds [Numeric] The seconds to wait for messages to be sent to the agent.
          def shutdown(wait_time_seconds = 30)
            # This is a blocking shutdown that will take no more messages
            # but it will wait until all messages are eaten from the queue
            @queue.close

            start = Time.now.utc
            until @queue.empty? || Time.now.utc > (start + wait_time_seconds)
              # Yield this thread until the queue has processed
              sleep(0)
            end

            @lock.synchronize do
              @stop = true
            end

            return if @sender_thread.nil?

            @sender_thread.join
          end

          def should_stop
            @lock.synchronize do
              @stop
            end
          end

          def create_client(host, port, opts)
            TCPClient.open("#{host}:#{port}", opts)
          end

          def start_sender(queue)
            @sender_thread = Thread.new do
              # Infinitely read from the queue and send messages to the agent
              conn = nil
              until should_stop
                if queue.empty?
                  # Thread yield; might be better to do a non-blocking `.pop`,
                  # but then we have constant exception handling. Yuck.
                  sleep(0)
                  next
                end

                message = queue.pop
                begin
                  if conn.nil? || conn.closed?
                    conn = create_client(@cw_agent_uri.host, @cw_agent_uri.port, @client_opts)
                  end

                  conn.write(message)
                rescue Errno::ECONNREFUSED
                  # Hopefully a transient issue, but the connection is gone. The sidecar may have died.
                  conn.close unless conn.nil? || conn.closed?
                  conn = nil
                  # Throw in a sleep so it doesn't hammer the connection trying to re-open.
                  # If the sleep is too short sockets may not be cleaned up fast enough by the OS,
                  # resulting in Errno::EMFILE: Too many open files - socket(2)
                  sleep(1)
                  # Unfortunately Ruby's thread-safe queue doesn't have a peek method.
                  # The message has to go to the tail
                  queue.push(message) unless queue.closed?
                rescue StandardError => e
                  queue.push(message) unless queue.closed?
                  log_err("#{e.class}: #{e.message}: #{e.backtrace.join("\n")}")
                end
              end

              conn&.close
            end
          end
        end
      end
    end
  end
end
