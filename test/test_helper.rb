$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require 'bundler' ; Bundler.require :default, :development, :test
require 'aws-embedded-metrics-customink'
require_relative 'test_helper/test_sink.rb'
require 'minitest/spec'
require 'minitest/autorun'

class TestCase < MiniTest::Spec

  before do
    reconfigure
    setup_test_sink
  end

  private

  def reconfigure
    Aws::Embedded::Metrics.reconfigure
  end

  def setup_test_sink
    Aws::Embedded::Metrics.stubs sink: test_sink
  end

  def test_sink
    @test_sink ||= TestSink.new
  end

end

require 'mocha/minitest'
