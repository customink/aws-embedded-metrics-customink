module Sinks
  class TestTcpSinkServer
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