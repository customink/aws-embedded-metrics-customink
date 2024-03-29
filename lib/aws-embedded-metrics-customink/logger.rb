module Aws
  module Embedded
    module Metrics
      class Logger

        def initialize(sink = Config.config.sink)
          @sink = sink
          @log_group_name = Config.config.log_group_name
          @log_stream_name = Config.config.log_stream_name
          @namespace = Config.config.namespace
          @dimensions = Concurrent::Array.new
          @metrics = Concurrent::Array.new
          @properties = Concurrent::Hash.new
        end

        def metrics
          yield(self)
        ensure
          flush
        end

        def flush
          @sink.accept(message) unless empty?
        end

        def benchmark
          value = nil
          seconds = Benchmark.realtime { value = yield }
          milliseconds = (seconds * 1000).to_i
          [value, milliseconds]
        end

        def put_dimension(name, value)
          @dimensions << { name => value }
          self
        end

        def put_metric(name, value, unit = nil)
          @metrics << { 'Name' => name }.tap do |m|
            m['Unit'] = unit if unit
          end
          set_property name, value
        end

        def set_property(name, value)
          @properties[name] = value
          self
        end

        def empty?
          [@dimensions, @metrics, @properties].all?(&:empty?)
        end

        def message
          aws = {
            'Timestamp' => timestamp,
            'CloudWatchMetrics' => [{
              'Namespace' => @namespace,
              'Dimensions' => [@dimensions.map(&:keys).flatten],
              'Metrics' => @metrics
            }]
          }

          aws['LogGroupName'] = @log_group_name if @log_group_name
          aws['LogStreamName'] = @log_stream_name if @log_stream_name

          {
            '_aws' => aws
          }.tap do |m|
            @dimensions.each { |dim| m.merge!(dim) }
            m.merge!(@properties)
          end
        end

        def timestamp
          Time.now.strftime('%s%3N').to_i
        end

      end
    end
  end
end
