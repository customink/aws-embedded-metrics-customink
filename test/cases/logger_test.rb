require 'test_helper'

class LoggerTest < TestCase

  it '.logger - no block' do
    Aws::Embedded::Metrics.logger
    expect(test_metrics).must_equal []
  end

  it '.logger - no config' do
    Aws::Embedded::Metrics.logger do |metrics|
      metrics.stubs timestamp: 1593474772574
      metrics.put_dimension 'SomeDimension', 'SomeDimensionValue'
      metrics.set_property  'EventKey', 'categories/4.jpg'
      metrics.put_metric    'ProcessorSmall', 232, 'Milliseconds'
      metrics.put_metric    'Total', 4008, 'Milliseconds'
    end
    expect(test_metrics[0]).must_equal({
      "_aws" => {
        "Timestamp"=>1593474772574,
        "CloudWatchMetrics" => [
          {
            "Namespace" => "aws-embedded-metrics",
            "Dimensions" => [["SomeDimension"]],
            "Metrics" => [
              {"Name" => "ProcessorSmall", "Unit" => "Milliseconds"},
              {"Name" => "Total", "Unit" => "Milliseconds"}
            ]
          }
        ]
      },
      "SomeDimension" => "SomeDimensionValue",
      "EventKey" => "categories/4.jpg",
      "ProcessorSmall" => 232,
      "Total" => 4008
    })
  end

  private

  def test_metrics
    test_sink.metrics
  end

end
