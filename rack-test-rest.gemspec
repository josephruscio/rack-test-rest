$:.push File.expand_path("../lib", __FILE__)

require 'rack-test-rest/version'

Gem::Specification.new do |s|
  s.name = "rack-test-rest"
  s.version = Rack::Test::Rest::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = "1.8.25"

  s.authors     = ["Joseph Ruscio"]
  s.email       = 'joe@ruscio.org'
  s.homepage    = 'https://github.com/josephruscio/rack-test-rest'
  s.license     = 'MIT'

  s.summary     = "Easy testing of RESTful API's with rack-test and Test::Unit."
  s.description = "Extends rack-test to simplifies the process of unit testing properly designed RESTful API's."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE.txt", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]
  s.extra_rdoc_files = [ "LICENSE.txt", "README.md" ]

  s.add_development_dependency 'rake'
end

