module Aws
  module Embedded
    module Metrics
      module Sinks
        class Logger

          attr_reader :logger, :level

          def initialize(logger, level: :info)
            @logger = logger
            @level = level.to_sym
          end

          def accept(message)
            logger.public_send(level, JSON.dump(message))
          end

        end
      end
    end
  end
end
