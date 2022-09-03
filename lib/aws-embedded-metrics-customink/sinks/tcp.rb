# frozen_string_literal: true

require 'tcp-client'

module Aws
  module Embedded
    module Metrics
      module Sinks
        #
        # Create a sink that will communicate to a CloudWatch Log Agent over a TCP connection.
        #
        # See https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format_Generation_CloudWatch_Agent.html
        # for configuration information
        class Tcp
          AWS_EMF_AGENT_ENDPOINT_ENV_VAR = 'AWS_EMF_AGENT_ENDPOINT'
          attr_reader :queue
          attr :client_opts

          #
          # Create a new TCP sink. It will use the +AWS_EMF_AGENT_ENDPOINT+ environment variable by default to
          # connect to a CloudWatch Metric Agent.
          #
          # @param conn_str [String] A connection string, formatted like 'tcp://127.0.0.1:25888'.
          # @param conn_timeout_secs [Numeric] The number of seconds before timing out the connection to the agent.
          # @param write_timeout_secs [Numeric] The number of seconds to wait before timing out a write.
          # @param logger [Logger] A standard Ruby logger to propagate warnings and errors.
          #   Suggested to use Rails.logger.
          def initialize(conn_str: ENV.fetch(AWS_EMF_AGENT_ENDPOINT_ENV_VAR, nil),
                         conn_timeout_secs: 10,
                         write_timeout_secs: 10,
                         logger: nil)
            if conn_str.nil?
              raise Sinks::Error, "Must specify a connection string or set environment variable #{AWS_EMF_AGENT_ENDPOINT_ENV_VAR}"
            end

            @logger = logger
            @cw_agent_uri = URI.parse(conn_str)
            if @cw_agent_uri.scheme != 'tcp' || !@cw_agent_uri.host || !@cw_agent_uri.port
              raise Sinks::Error, "Expected connection string to be in format tcp://<host>:<port>, got '#{conn_str}'"
            end

            @client_opts = TCPClient::Configuration.create(
              buffered: true,
              keep_alive: true,
              reverse_lookup: true,
              connect_timeout: conn_timeout_secs,
              write_timeout: write_timeout_secs
            )
            @conn = nil
          end

          def log_warn(msg)
            @logger&.warn(msg)
          end

          def log_err(msg)
            @logger&.error(msg)
          end

          def create_conn(host, port, opts)
            TCPClient.open("#{host}:#{port}", opts)
          end

          def connection
            @conn = create_conn(@cw_agent_uri.host, @cw_agent_uri.port, @client_opts) if @conn.nil? || @conn.closed?
            @conn
          end

          def send_message(message)
            retries = 2
            conn = nil
            begin
              conn = connection
              conn.write(message)
            rescue Errno::ECONNREFUSED
              conn.close unless conn.nil? || conn.closed?
              log_warn("Could not connect to CloudWatch Agent at #{@cw_agent_uri.scheme}://#{@cw_agent_uri.host}:#{@cw_agent_uri.port}")
              retries -= 1
              retry if retries >= 0
            rescue StandardError => e
              log_err("#{e.class}: #{e.message}: #{e.backtrace.join("\n")}")
            end
          end

          def accept(message)
            send_message("#{JSON.dump(message)}\n")
          end
        end
      end
    end
  end
end
