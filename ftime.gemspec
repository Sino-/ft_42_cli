Gem::Specification.new do |s|
  s.name        = 'ftime'
  s.version     = '0.0.1'
  s.summary     = "Time management for 42 students"
  s.description = "Check time you've spent in the clusters"
  s.authors     = ["Matias Fernandez"]
  s.email       = 'matiasfmolinari@gmail.com'
  s.homepage    = 'http://rubygems.org/gems/ft_time'
  s.license     = 'MIT'

  s.files         = ["lib/ft_time.rb"]
  s.require_paths = ["lib"]

  s.add_dependency 'active_support/all'
  s.add_dependency 'action_view'
  s.add_dependency 'pastel'
  s.add_dependency 'oauth2'
  s.add_dependency 'ruby-progressbar'
end
