$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__)).uniq!
require "tnetstring/version"

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'tnetstring'
  s.version     = TNetstring::Version::STRING
  s.summary     = "Ruby implementation of the tagged netstring specification."
  s.description = "Ruby implementation of the tagged netstring specification, a simple data interchange format better suited to low-level network communication than JSON. See http://tnetstrings.org/ for more details."

  s.required_ruby_version     = '>= 1.8.7'
  s.required_rubygems_version = ">= 1.3.7"

  s.files = `git ls-files -- lib/*`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  
  s.extra_rdoc_files = [
    "HISTORY.rdoc",
    "MIT-LICENSE",
    "README.rdoc"
  ]

  s.author            = 'Matt Yoho'
  s.email             = 'mby@mattyoho.com'
  s.homepage          = 'http://github.com/mattyoho/tnetstring-rb'

  s.add_development_dependency('bundler', '>= 1.0.12')
  s.add_development_dependency('rake', '>= 0.9.1')
  s.add_development_dependency('rspec', '~> 2.5.0')
end
