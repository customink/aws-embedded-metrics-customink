module Aws
  module Embedded
    module Metrics
      module Config

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

        extend self

        class Configuration

          attr_writer :namespace

          def reconfigure
            instance_variables.each { |var| instance_variable_set var, nil }
            yield(self) if block_given?
            self
          end

          def namespace
            return @namespace if defined?(@namespace)
            ENV['AWS_EMF_NAMESPACE'] || 'aws-embedded-metrics'
          end

        end
      end
    end
  end
end
