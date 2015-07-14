$:.push File.expand_path("../lib", __FILE__)
$:.push File.expand_path("../lib/as-combined-metrics", __FILE__)

require File.expand_path('../lib/as-combined-metrics', __FILE__)

Gem::Specification.new do |s|
  s.name        = "as-combined-metrics"
  s.version     = AsCombinedMetrics::VERSION
  s.authors     = ["Ami Mahloof"]
  s.email       = "ami.mahloof@gmail.com"
  s.homepage    = "https://github.com/innovia/AwsCombinedMetrics"
  s.summary     = "submit custom AWS CloudWatch metric that combines several other thresholds for scale in or out"
  s.description = "AWS custom combined metric CloudWatch tool"
  s.required_rubygems_version = ">= 1.3.6"
  s.files = `git ls-files`.split($\).reject{|n| n =~ %r[png|gif\z]}.reject{|n| n =~ %r[^(test|spec|features)/]}
  s.add_runtime_dependency 'thor', '~> 0.19', '>= 0.19.1'
  s.add_runtime_dependency 'aws-sdk', '~> 2.0.45', '>= 2.0.45'
  s.add_runtime_dependency 'activesupport', '~> 4.2.3', '>= 4.2.3'
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.extra_rdoc_files = ['README.md', 'LICENSE']
  s.license = 'MIT'
end
