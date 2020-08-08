module Aws
  module Embedded
    module Metrics
      class Instance < SimpleDelegator
        mattr_accessor :instance

        extend SingleForwardable

        def_delegators :instance,
                       :flush,
                       :benchmark,
                       :put_dimension,
                       :put_metric,
                       :set_property
      end
    end
  end
end
