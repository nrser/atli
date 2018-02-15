# coding: utf-8
lib = File.expand_path("../lib/", __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)
require "thor/version"

Gem::Specification.new do |spec|
  spec.add_development_dependency "bundler", "~> 1.0"
  spec.authors = ["Neil Souza (Atli)", "Yehuda Katz (Thor)", "José Valim (Thor)"]
  spec.description = "Atli is a fork of Thor that's better or worse."
  spec.email = "neil@atli.nrser.com"
  spec.executables = %w(thor)
  spec.files = %w(.yardopts atli.gemspec) + Dir["*.md", "bin/*", "lib/**/*.rb"]
  spec.homepage = "https://github.com/nrser/atli"
  spec.licenses = %w(MIT)
  spec.name = "atli"
  spec.require_paths = %w(lib)
  spec.required_ruby_version = ">= 1.8.7"
  spec.required_rubygems_version = ">= 1.3.5"
  spec.summary = spec.description
  spec.version = Thor::VERSION
  
  # Dependencies
  # ============================================================================
  # 
  # NOTE Development dependencies are in `//Gemfile`
  # 
  
  # My guns
  spec.add_dependency "nrser", '~> 0.1', ">= 0.1.2"
end
