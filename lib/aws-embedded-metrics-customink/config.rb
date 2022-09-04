module Aws
  module Embedded
    module Metrics
      module Config

        DEFAULT_SINK = Sinks::Stdout

        def configure
          yield(config)
          config
        end

        def reconfigure
          config.reconfigure { |c| yield(c) if block_given? }
        end

        def config
          @config ||= Configuration.new
        end

        module_function :configure, :reconfigure, :config

        class Configuration

          attr_writer :log_group_name,
                      :log_stream_name,
                      :namespace,
                      :service_name,
                      :service_type,
                      :sink

          def reconfigure
            instance_variables.each { |var| instance_variable_set var, nil }
            yield(self) if block_given?
            self
          end

          def log_group_name
            return @log_group_name if defined?(@log_group_name)

            ENV.fetch('AWS_EMF_LOG_GROUP_NAME', nil)
          end

          def log_stream_name
            return @log_stream_name if defined?(@log_stream_name)

            ENV.fetch('AWS_EMF_LOG_STREAM_NAME', nil)
          end

          def namespace
            return @namespace if defined?(@namespace)

            ENV.fetch('AWS_EMF_NAMESPACE', 'aws-embedded-metrics')
          end

          def service_name
            return @service_name if defined?(@service_name)

            ENV.fetch('AWS_EMF_SERVICE_NAME', nil)
          end

          def service_type
            return @service_type if defined?(@service_type)

            ENV.fetch('AWS_EMF_SERVICE_TYPE', nil)
          end

          def sink
            @sink ||= DEFAULT_SINK.new
          end
        end
      end
    end
  end
end
