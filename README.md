# Aws::Embedded::Metrics for Ruby [![Actions Status](https://github.com/customink/aws-embedded-metrics-customink/workflows/CI/badge.svg)](https://github.com/customink/aws-embedded-metrics-customink/actions)

⚠️ Bare minimum code to explore [Amazon CloudWatch Embedded Metrics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format.html) with Ruby. Any and all help welcome to raise the quality of our implementation.

[Enhancing workload observability using Amazon CloudWatch Embedded Metric Format](https://awsfeed.com/whats-new/management-tools/enhancing-workload-observability-using-amazon-cloudwatch-embedded-metric-format)

#### Inspiration

Pulled from these two projects using the [Embedded Metric Format Specification](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format_Manual.html) as a reference guide.

* Node: https://github.com/awslabs/aws-embedded-metrics-node
* Python: https://github.com/awslabs/aws-embedded-metrics-python

However, unlike these projects, we differ in the following ways. Again, contributions are very much welcome if you want to see more or change this.

* Initial focus on Lambda. A TCP sink has been added, but no UDP sink exists.
* An async sink wrapper exists that allows messages to be queued and sent on a separate thread.
* No default Dimensions or Configuration for:
  - `ServiceName`
  - `ServiceType`

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aws-embedded-metrics-customink'
```
## Usage

If using outside of Rails, require the gem:
```ruby
require 'aws-embedded-metrics-customink'
```

Simple configuration:

```ruby
Aws::Embedded::Metrics.configure do |c|
  c.namespace = 'MyApplication'
  # Optional
  c.log_group_name = 'MyLogGroup'
  c.log_stream_name = 'MyLogStream-UniqueID' 
end
```

Using the `Logger` sink to write to a log file:

```ruby
Aws::Embedded::Metrics.configure do |c|
  c.sink = Aws::Embedded::Metrics::Sinks::Logger.new(Rails.logger)
end
```

Using the `Tcp` sink to write over a network:

```ruby
Aws::Embedded::Metrics.configure do |c|
  c.sink = Aws::Embedded::Metrics::Sinks::Tcp.new(conn_str: "tcp://localhost:25888",
                                                  logger: Rails.logger)
end
```

Using the `Async` sink wrapper to incur no latency or errors on writes:
```ruby
Aws::Embedded::Metrics.configure do |c|
  tcp_sink = Aws::Embedded::Metrics::Sinks::Tcp.new(conn_str: "tcp://localhost:25888",
                                                    logger: Rails.logger)
  c.sink = Aws::Embedded::Metrics::Sinks::Async.new(tcp_sink, logger: Rails.logger, max_queue_size: 1_000)
end
```

Usage is in a scope block. All metrics are flushed afterward

```ruby
Aws::Embedded::Metrics.logger do |metrics|
  metrics.put_dimension 'SomeDimension', 'SomeDimensionValue'
  metrics.set_property  'EventKey', 'some/s3/path'
  metrics.put_metric    'Processor', 232, 'Milliseconds'
  metrics.put_metric    'Total', 4008, 'Milliseconds'
end
```

## Using Rails?

And want to instrument metrics deep in your code during the request/response lifecycle? Consider creating a PORO like this `Metrics` example.

```ruby
class MyMetrics < Aws::Embedded::Metrics::Instance
end
```

This object is ready to use as a per-request singleton that acts as a simple delegator to all metrics/logger methods. A great way to hook it up for your application is in ApplicationController.

```ruby
class ApplicationController < ActionController::Base
  around_action :embedded_metrics
  private
  def embedded_metrics
    Aws::Embedded::Metrics.logger do |metrics|
      MyMetrics.instance = MyMetrics.new(metrics)
      yield
    end
  end
end
```

Now you can happily instrument your code.

```ruby
proof, time = MyMetrics.benchmark { @imagebuilder.data }
MyMetrics.put_metric 'ImageBuilderTime', time, 'Milliseconds'
MyMetrics.set_property 'ImageId', params[:image_id]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/customink/aws-embedded-metrics-customink. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/customink/aws-embedded-metrics-customink/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Aws::Embedded::Metrics project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/customink/aws-embedded-metrics-customink/blob/master/CODE_OF_CONDUCT.md).
