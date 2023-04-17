require 'json'
require 'benchmark'
require 'concurrent/array'
require 'concurrent/hash'
require 'aws-embedded-metrics-customink/version'
require 'aws-embedded-metrics-customink/sinks'
require 'aws-embedded-metrics-customink/config'
require 'aws-embedded-metrics-customink/logger'
require 'aws-embedded-metrics-customink/units'
require 'aws-embedded-metrics-customink/instance' if defined?(Rails)

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

      module_function :config, :configure, :reconfigure, :logger

    end
  end
end
