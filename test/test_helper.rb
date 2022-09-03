$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require 'bundler' ; Bundler.require :default, :development, :test
require 'aws-embedded-metrics-customink'
require_relative 'test_helper/test_sink.rb'
require_relative 'test_helper/test_tcp_sink_server.rb'
require 'minitest/spec'
require 'minitest/autorun'

class TestCase < MiniTest::Spec

  before do
    configure
  end

  private

  def configure
    Aws::Embedded::Metrics.reconfigure do |c|
      c.sink = test_sink
    end
  end

  def test_sink
    @test_sink ||= TestSink.new
  end

end

require 'mocha/minitest'
