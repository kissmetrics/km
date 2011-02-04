# -*- encoding: utf-8 -*-
require File.expand_path("../lib/km/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "kissmetrics"
  s.version     = KM::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["KISSmetrics"]
  s.email       = ["support@kissmetrics.com"]
  s.homepage    = "http://rubygems.org/gems/km"
  s.summary     = "KISSmetrics ruby API gem"
  s.description = "KISSmetrics ruby API gemtion"

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "kissmetrics"

  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "rspec", "~> 2.4.0"
  s.add_development_dependency "awesome_print"
  s.add_development_dependency "rake"
  s.add_development_dependency "watchr"

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
