require 'test_helper'
require 'thread'

module Sinks
  class EcsFargateTest < TestCase
    let(:port) { 23999 }
    let(:server) { TcpSinkServer.new(port) }
    let(:msg) { { hello: 'world' } }
    let(:max_queue_size) { 3 }
    let(:logger_content) { StringIO.new }
    let(:logger) { Logger.new logger_content }
    let(:sink) do
      Aws::Embedded::Metrics::Sinks::EcsFargate.new(conn_str: "tcp://localhost:#{port}",
                                                    max_queue_size: max_queue_size,
                                                    conn_timeout_secs: 2,
                                                    write_timeout_secs: 1,
                                                    logger: logger)
    end

    it 'initializes with a connection string' do
      expect(sink).must_be_instance_of Aws::Embedded::Metrics::Sinks::EcsFargate
    end

    it '#accept dumps its message to the server' do
      server.start

      sink.accept(msg)
      sink.accept(msg)
      sink.accept(msg)

      sink.shutdown(1)
      server.stop

      assert_equal(server.data.length, 3)
      (0..2).each { |i|
        assert_equal(JSON.dump(msg), server.data[i].strip)
      }
    end

    it '#accept throws if sending a message after it is shutdown' do
      sink.shutdown(1)
      assert_raises(ClosedQueueError) {
        sink.accept(msg)
      }
    end

    it 're-creates the connection if the connection is refused' do
      # Create 2 fake clients that are returned on separate calls to create_client
      # Send 2 messages, both of which will fail, forcing new clients.
      fake_client1 = TCPClient.new
      fake_client1.stubs(:write).raises(Errno::ECONNREFUSED, 'Expected').once

      fake_client2 = TCPClient.new
      fake_client2.stubs(:write).raises(Errno::ECONNREFUSED, 'Expected').once

      sink.stubs(:create_client).returns(fake_client1, fake_client2)

      sink.accept(msg)
      sink.accept(msg)
      sink.shutdown(1)
    end

    it 'reports unexpected errors over the logger' do
      # Create 2 fake clients that are returned on separate calls to create_client
      # Send 2 messages, both of which will fail, forcing new clients.
      fake_client = TCPClient.new
      fake_client.stubs(:write).raises(StandardError, 'Expected to fail')

      sink.stubs(:create_client).returns(fake_client)

      sink.accept(msg)
      sink.shutdown(1)

      assert_match(/StandardError/, logger_content.string, 'StandardError should have been logged')
      assert_match(/Expected to fail/, logger_content.string, 'The error message should have been logged')
    end

    it 'reports queue sizes over the max over the logger' do
      (0..max_queue_size + 2).each do |i|
        sink.accept("Message #{i}")
      end

      sink.shutdown(1)
      assert_equal(2, logger_content.string.split("\n").length, "There should be 2 messages dropped")
      assert_match(/Queue is full/, logger_content.string, "The message should indicate the queue is full")
    end

    class TcpSinkServer
      def initialize(port)
        @port = port
        @lock = Mutex.new
        @data_queue = Queue.new
        @data = ''
        @stop = false
        @server = nil
      end

      def data
        until @data_queue.empty?
          @data += @data_queue.pop
        end
        @data.split("\n")
      end

      def stop
        @lock.synchronize do
          @stop = true
        end
        close_server
        @server_thread.join
      end

      def should_stop
        @lock.synchronize do
          @stop
        end
      end

      def start
        @server_thread = Thread.new {
          begin
            @server = TCPServer.open(@port)
            client = accept_client

            read_from_socket(client)

            unless client.nil?
              client.close
            end

            close_server
          rescue StandardError => e
            puts "Server Error! #{e}"
            puts e.backtrace
            close_server
          end
        }
      end

      def accept_client
        begin
          if should_stop
            # If we should stop running, return now before accepting a client
            close_server
            return
          end

          client = @server.accept_nonblock
          # If we don't set the client to UTF-8 it encodes the response as ASCII and the test fails
          client.set_encoding('UTF-8')
          return client
        rescue IO::WaitReadable, Errno::EINTR
          # The "correct" thing to do here is
          # IO.select([@server]), which waits until a new connection is available on the socket.
          # Good thing we aren't making a real server.
          # Just spin-wait and exit if we get an exit signal.
          sleep(0)
          retry
        end
      end

      def read_from_socket(sock)
        if sock.nil?
          return
        end

        until sock.closed?
          begin
            if should_stop
              return
            end
            line = sock.read_nonblock(512)
          rescue IO::WaitReadable
            # The "correct" thing to do here is
            # IO.select([sock]), which waits until data is available on the socket.
            # Good thing we aren't making a real server.
            # Just spin-wait and exit if we get an exit signal.
            sleep(0)
            retry
          rescue EOFError
            return
          end

          return if line.nil?
          @data_queue << line
        end
      end

      def close_server
        @server&.close
        @data_queue.close
      end
    end
  end
end
