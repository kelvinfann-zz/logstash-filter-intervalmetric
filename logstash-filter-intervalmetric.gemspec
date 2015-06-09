Gem::Specification.new do |s|
  s.name = 'logstash-filter-intervalmetrics'
  s.version         = '0.0.1'
  s.licenses = ['Apache License (2.0)']
  s.summary = "The intervalmetric filter is a stripped down version of the metric filter used to count the number of messages accross an interval of time."
  s.description = "This gem is a logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/plugin install gemname. This gem is not a stand-alone program"
  s.authors = ["Elastic", "Kelvin"]
  s.email = 'kelvinfann@outlook.com'
  s.homepage = "https://github.com/kelvinfann"
  s.require_paths = ["lib"]

  # Files
  s.files = `git ls-files`.split($\)
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "filter" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core", '>= 1.4.0', '< 2.0.0'
  s.add_runtime_dependency "metriks"
  s.add_runtime_dependency "thread_safe"
  s.add_development_dependency 'logstash-devutils'
end
