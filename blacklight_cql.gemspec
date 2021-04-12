# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), "lib/blacklight_cql/version")

Gem::Specification.new do |s|
  s.name = "blacklight_cql"
  s.version = BlacklightCql::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Jonathan Rochkind"]
  s.email = ["blacklight-development@googlegroups.com"]
  s.homepage    = "http://projectblacklight.org/"
  s.summary = "Blacklight CQL plugin"

  s.rubyforge_project = "blacklight"

  s.files = Dir["lib/**/*", "app/**/*", "config/**/*", "VERSION"]
  s.test_files    = Dir["app_root/**/*", "spec/**/*"]

  s.require_paths = ["lib"]

  s.add_dependency "rails"
  s.add_dependency "blacklight", ">= 5.14.0"
  s.add_dependency "cql-ruby", ">=0.8.1"


  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails", "~> 2.6"
  s.add_development_dependency "nokogiri"
  s.add_development_dependency "engine_cart"


end
