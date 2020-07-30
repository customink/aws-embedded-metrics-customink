require 'json'
require 'benchmark'
require 'aws-embedded-metrics-customink/version'
require 'aws-embedded-metrics-customink/sinks'
require 'aws-embedded-metrics-customink/config'
require 'aws-embedded-metrics-customink/logger'

module Aws
  module Embedded
    module Metrics

      def config
        Config.config
      end

      def configure
        Config.configure { |c| yield(c) }
      end

      def reconfigure
        Config.reconfigure { |c| yield(c) if block_given? }
      end

      def logger
        Logger.new.tap do |l|
          l.metrics { |m| yield(m) } if block_given?
        end
      end

      extend self

    end
  end
end
