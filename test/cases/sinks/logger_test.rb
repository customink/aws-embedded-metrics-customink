require 'logger'
require 'stringio'

module Sinks
  class LoggerTest < TestCase
    let(:logger) { Logger.new(StringIO.new) }
    let(:level) { :info }
    let(:msg) { { hello: 'world' } }
    let(:sink) { Aws::Embedded::Metrics::Sinks::Logger.new(logger, level: level) }

    it 'initializes with an instance of a logger and a log level' do
      expect(sink).must_be_instance_of Aws::Embedded::Metrics::Sinks::Logger
      expect(sink.logger).must_equal logger
      expect(sink.level).must_equal level
    end

    it '#accept dumps its message as json to the logger at the prescribed log level' do
      logger.expects(:info).with(JSON.dump(msg)).once
      sink.accept(msg)
    end
  end
end
