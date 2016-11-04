Gem::Specification.new do |s|
  s.name        = 'ft_42'
  s.version     = '0.0.2'
  s.summary     = "Info for 42 students"
  s.description = "General information for 42 students"
  s.authors     = ["Matias Fernandez"]
  s.email       = 'matiasfmolinari@gmail.com'
  s.homepage    = 'http://rubygems.org/gems/ft_42'
  s.license     = 'MIT'

  s.executables << 'ft_42'

  s.files         = ["lib/ft_42.rb"]
  s.require_paths = ["lib"]

  s.add_dependency 'active_support/all'
  s.add_dependency 'action_view'
  s.add_dependency 'pastel'
  s.add_dependency 'oauth2'
  s.add_dependency 'ruby-progressbar'
  s.add_dependency 'dotenv'
end
