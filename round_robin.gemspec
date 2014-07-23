Gem::Specification.new do |gem|
  gem.name        = 'round_robin'
  gem.version     = '0.1'
  gem.date        = '2014-05-12'
  gem.summary     = "Round robin annotation"
  gem.description = "See summary"
  gem.authors     = ["Chris Boursnell", "Richard Smith-Unna"]
  gem.email       = 'cmb211@cam.ac.uk'
  gem.files       = ["lib/round_robin.rb", "lib/record.rb", "bin/robin"]
  gem.executables = ["robin"]
  gem.require_paths = %w( lib )
  gem.homepage    = 'http://rubygems.org/gems/round-robin'
  gem.license     = 'MIT'

  gem.add_dependency 'trollop', '~> 2.0'
  gem.add_dependency 'crb-blast', '~> 0.4', '>= 0.4.0'
  gem.add_dependency 'threach', '~> 0.2', '>= 0.2.0'
  gem.add_dependency 'bio', '~> 1.4', '>= 1.4.3'
  gem.add_dependency 'rgl', '~> 0.4', '>= 0.4.0'
  gem.add_dependency 'which', '0.0.2'

  gem.add_development_dependency 'rake', '~> 10.3', '>= 10.3.2'
  gem.add_development_dependency 'turn', '~> 0.9', '>= 0.9.7'
  gem.add_development_dependency 'simplecov', '~> 0.8', '>= 0.8.2'
  gem.add_development_dependency 'shoulda-context', '~> 1.2', '>= 1.2.1'
  gem.add_development_dependency 'coveralls', '~> 0.7'
end