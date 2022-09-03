require 'test_helper'
require 'thread'

module Sinks
  class AsyncTest < TestCase
    let(:port) { 23999 }
    let(:server) { TestTcpSinkServer.new(port) }
    let(:msg) { { hello: 'world' } }
    let(:max_queue_size) { 3 }
    let(:logger_content) { StringIO.new }
    let(:logger) { Logger.new logger_content }
    let(:wrapped_sink) do
      Aws::Embedded::Metrics::Sinks::Tcp.new(conn_str: "tcp://localhost:#{port}",
                                             conn_timeout_secs: 2,
                                             write_timeout_secs: 1,
                                             logger: logger)
    end
    let(:sink) do
      Aws::Embedded::Metrics::Sinks::Async.new(wrapped_sink,
                                               logger: logger,
                                               max_queue_size: max_queue_size)
    end

    it 'initializes with a connection string' do
      expect(sink).must_be_instance_of Aws::Embedded::Metrics::Sinks::Async
    end

    it '#accept dumps its message to the server' do
      server.start

      sink.accept(msg)
      sink.accept(msg)
      sink.accept(msg)

      sink.shutdown(1)
      Timeout::timeout(1) {
        until server.data.length >= 3;
        end
      }

      assert_equal(3, server.data.length)
      (0..2).each { |i|
        assert_equal(JSON.dump(msg), server.data[i].strip)
      }
      server.stop
    end

    it '#accept throws if sending a message after it is shutdown' do
      sink.shutdown(1)
      assert_raises(ClosedQueueError) {
        sink.accept(msg)
      }
    end

    it 'reports queue sizes over the max over the logger' do
      (0..max_queue_size + 2).each do |i|
        sink.accept("Message #{i}")
      end

      sink.shutdown(1)
      assert_equal(2,
                   logger_content.string.scan("Async metrics queue is full").length,
                   "There should be 2 messages dropped")
    end
  end
end
