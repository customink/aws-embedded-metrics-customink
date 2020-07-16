# Aws::Embedded::Metrics for Ruby [![Actions Status](https://github.com/customink/aws-embedded-metrics-customink/workflows/CI/badge.svg)](https://github.com/customink/aws-embedded-metrics-customink/actions)

⚠️ Bare minimum code to explore [Amazon CloudWatch Embedded Metrics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format.html) with Ruby. Any and all help welcome to raise the quality of our implementation.

[Enhancing workload observability using Amazon CloudWatch Embedded Metric Format](https://awsfeed.com/whats-new/management-tools/enhancing-workload-observability-using-amazon-cloudwatch-embedded-metric-format)

#### Inspiration

Pulled from these two projects using the [Embedded Metric Format Specification](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format_Manual.html) as a reference guide.

* Node: https://github.com/awslabs/aws-embedded-metrics-node
* Python: https://github.com/awslabs/aws-embedded-metrics-python

However, unlike these projects, we differ in the following ways. Again, contributions are very much welcome if you want to see more or change this.

* Initial focus on Lambda. No other sinks.
* As such, no default Dimensions or Configuraiton for:
  - `LogGroupName`
  - `LogStreamName`
  - `ServiceName`
  - `ServiceType`

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aws-embedded-metrics-customink'
```
## Usage

Simple configuration.

```ruby
Aws::Embedded::Metrics.configure do |c|
  c.namespace = 'MyApplication'
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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/customink/aws-embedded-metrics-customink. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/customink/aws-embedded-metrics-customink/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Aws::Embedded::Metrics project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/customink/aws-embedded-metrics-customink/blob/master/CODE_OF_CONDUCT.md).
