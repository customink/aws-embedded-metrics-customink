require 'test_helper'
require 'thread'

module Sinks
  class TcpTest < TestCase
    let(:port) { 23999 }
    let(:server) { TestTcpSinkServer.new(port) }
    let(:msg) { { hello: 'world' } }
    let(:logger_content) { StringIO.new }
    let(:logger) { Logger.new logger_content }
    let(:sink) do
      Aws::Embedded::Metrics::Sinks::Tcp.new(conn_str: "tcp://localhost:#{port}",
                                             conn_timeout_secs: 2,
                                             write_timeout_secs: 1,
                                             logger: logger)
    end

    it 'initializes with a connection string' do
      expect(sink).must_be_instance_of Aws::Embedded::Metrics::Sinks::Tcp
    end

    it '#accept dumps its message to the server' do
      server.start

      sink.accept(msg)
      sink.accept(msg)
      sink.accept(msg)
      sink.connection.close

      Timeout::timeout(1) {
        until server.data.length == 3; end
      }

      assert_equal(3, server.data.length)
      (0..2).each { |i|
        assert_equal(JSON.dump(msg), server.data[i].strip)
      }
      server.stop
    end

    it 're-creates the connection if the connection is refused with retries' do
      # Create 2 fake clients that are returned on separate calls to create_client
      # Send 2 messages, both of which will fail, forcing new clients.
      fake_client1 = TCPClient.new
      fake_client1.stubs(:write).raises(Errno::ECONNREFUSED, 'Expected').once

      fake_client2 = TCPClient.new
      fake_client2.stubs(:write).raises(Errno::ECONNREFUSED, 'Expected').times(2)

      sink.stubs(:connection).returns(fake_client1, fake_client2)

      sink.accept(msg)
    end

    it 'reports unexpected errors over the logger' do
      # Create 2 fake clients that are returned on separate calls to create_client
      # Send 2 messages, both of which will fail, forcing new clients.
      fake_client = TCPClient.new
      fake_client.stubs(:write).raises(StandardError, 'Expected to fail')

      sink.stubs(:connection).returns(fake_client)

      sink.accept(msg)

      assert_match(/StandardError/, logger_content.string, 'StandardError should have been logged')
      assert_match(/Expected to fail/, logger_content.string, 'The error message should have been logged')
    end
  end
end
