# frozen_string_literal: true

require 'tcp-client'

module Aws
  module Embedded
    module Metrics
      module Sinks
        #
        # Create a sink that will immediately take in messages, enqueue them, and forward them on to a sink.
        class Async
          attr_reader :queue, :sender

          #
          # Create a new Async sink which wraps an existing sink. This is most beneficial with the tcp sink.
          #
          # This was built as a performance-critical piece of code since metrics are often sent in high volumes.
          # +#accept+, which is what takes in messages to send to the CW Metric Agent, puts messages into a thread-safe
          # queue. A separate thread is then picking up from that queue and sending the messages to the chosen sink.
          #
          # <b>Creating a new Async sink will create a new thread.</b> This sink is intended to be used sparingly.
          #
          # Messages that sent to the sink; no more information is known about the message after that.
          # If the sink cannot process the message, it is lost.
          #
          # If a message is enqueued and the queue is full, the message is dropped and a warning is logged.
          # @param sink [Sink] A sink to wrap. +#accept+ will be the only method called on the sink.
          # @param logger [Logger] A standard Ruby logger to propagate warnings and errors.
          #   Suggested to use Rails.logger.
          # @param max_queue_size [Numeric] The number of messages to buffer in-memory.
          #   A negative value will buffer everything.
          def initialize(sink,
                         logger: nil,
                         max_queue_size: 1_000)
            raise Sinks::Error, 'Must specify a sink to wrap' if sink.nil?

            @sink = sink

            @max_queue_size = max_queue_size
            @queue = Queue.new
            @lock = Mutex.new
            @stop = false
            @logger = logger
            start_sender(@queue)
          end

          def accept(message)
            if @max_queue_size > -1 && @queue.length > @max_queue_size
              @logger&.warn("Async metrics queue is full (#{@max_queue_size} items)! Dropping metric message.")
              return
            end

            @queue.push(message)
          end

          #
          # Shut down the sink. By default this blocks until all messages are sent to the agent, or
          # the wait time elapses. No more messages will be accepted as soon as this is called.
          #
          # @param wait_time_seconds [Numeric] The seconds to wait for messages to be sent to the agent.
          def shutdown(wait_time_seconds = 30)
            # We push a "stop" message to ensure there's something in the queue,
            # otherwise it will indefinitely block.
            # When a "stop message" comes through it will break the loop.
            @queue.push(StopMessage.new)
            @queue.close

            start = Time.now.utc
            until @queue.empty? || Time.now.utc > (start + wait_time_seconds)
              # Yield this thread until the queue has processed
              sleep(0)
            end

            # If we haven't been able to eat through the queue, this should terminate the loop
            # and allow the thread to rejoin.
            @lock.synchronize do
              @stop = true
            end

            @sender_thread&.join
          end

          def should_stop
            @lock.synchronize do
              @stop
            end
          end

          def start_sender(queue)
            @sender_thread = Thread.new do
              stop_message_class = StopMessage.new.class
              # Infinitely read from the queue and send messages to the agent
              until should_stop
                # We use a special message class to ensure
                message = queue.pop
                break if stop_message_class == message.class

                @sink.accept(message)
              end
            end
          end

          # Special class to signal that the thread should exit and finish.
          class StopMessage; end
          private_constant :StopMessage
        end
      end
    end
  end
end
