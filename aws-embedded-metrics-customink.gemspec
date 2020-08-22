require_relative 'lib/aws-embedded-metrics-customink/version'

Gem::Specification.new do |spec|
  spec.name          = "aws-embedded-metrics-customink"
  spec.version       = Aws::Embedded::Metrics::VERSION
  spec.authors       = ["Ken Collins"]
  spec.email         = ["ken@metaskills.net"]
  spec.summary       = 'Amazon CloudWatch Embedded Metric Format Client Library'
  spec.description   = 'Amazon CloudWatch Embedded Metric Format Client Library for Ruby.'
  spec.homepage      = 'https://github.com/customink/aws-embedded-metrics-customink'
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/customink/aws-embedded-metrics-customink'
  spec.metadata['changelog_uri'] = 'https://github.com/customink/aws-embedded-metrics-customink/blob/master/CHANGELOG.md'
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency 'concurrent-ruby'
end
