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

  gem.add_dependency 'trollop'
  gem.add_dependency 'rake'
  gem.add_dependency 'crb-blast'
  gem.add_dependency 'threach'
  gem.add_dependency 'bio', '~> 1.4', '>= 1.4.3'
  gem.add_dependency 'rgl'
  gem.add_dependency 'which', '0.0.2'

  gem.add_development_dependency 'turn'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'shoulda-context'
  gem.add_development_dependency 'coveralls', '>= 0.6.7'
end