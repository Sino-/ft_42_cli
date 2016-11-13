Gem::Specification.new do |gem|
  gem.name        = 'ft_42'
  gem.version     = '0.1.0'
  gem.summary     = "Info for 42 students"
  gem.description = "General information for 42 students"
  gem.authors     = ["Matias Fernandez"]
  gem.email       = 'matiasfmolinari@gmail.com'
  gem.homepage    = 'http://rubygems.org/gems/ft_42'
  gem.license     = 'MIT'

  gem.executables << 'ft_42'

  gem.files         = ["lib/ft_42.rb", "bin/ft_42", "test/test_ft_42.rb"]
  gem.require_paths = ["lib"]

  gem.add_dependency 'activesupport', '~> 5.0', '>= 5.0.0.1'
  gem.add_dependency 'pastel', '~> 0.6.1'
  gem.add_dependency 'oauth2', '~> 1.2'
  gem.add_dependency 'ruby-progressbar', '~> 1.8', '>= 1.8.1'
end
