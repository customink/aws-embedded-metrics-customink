module Aws
  module Embedded
    module Metrics
      module Sinks
        class Lambda

          def accept(message)
            puts JSON.dump(message)
          end

        end
      end
    end
  end
end
