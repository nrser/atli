# coding: utf-8
lib = File.expand_path("../lib/", __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)
require "thor/version"

Gem::Specification.new do |spec|
  spec.authors = ["Neil Souza (Atli)", "Yehuda Katz (Thor)", "José Valim (Thor)"]
  spec.description = "Atli is a fork of Thor that's better or worse."
  spec.email = "neil@atli.nrser.com"
  spec.executables = %w(thor)

  spec.files = [
    '.yardopts',
    'atli.gemspec',
    'support/completion/complete.inc.bash.erb',
  ] + Dir[
    "*.md",
    "bin/*",
    "lib/**/*.rb",
  ]

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
  
  # My guns
  spec.add_dependency "nrser", '~> 0.3.9'
  
  
  # Development Dependencies
  # ----------------------------------------------------------------------------
  # 
  # NOTE Development dependencies that came from Thor are in `//Gemfile`
  # 
  
  spec.add_development_dependency "bundler", ">= 1.0"
  
  ### Yard
  # 
  # I'm not used to dealing with RDoc docstrings, and want to still write doc
  # files in Markdown, but it's been funky to get them to work together...
  # 
  # When things get funky:
  # 
  # 1.  `qb yard/clean`
  # 2.  `bundle exec yard doc`
  # 3.  `locd site restart yard.atli`
  # 
  
  # Doc site generation with `yard`
  spec.add_development_dependency 'yard', '~> 0.9.12'
  # Add support for {ActiveSupport::Concern} to Yard
  spec.add_development_dependency 'yard-activesupport-concern', '~> 0.0.1'
  
  # This being installed *seems* to help Yard do the right things with
  # markdown files...
  spec.add_development_dependency 'redcarpet', '~> 3.4'
  
  # These... do not seem to work or help...
  # 
  # GitHub-Flavored Markdown (GFM) for use with `yard`
  # spec.add_development_dependency 'github-markup', '~> 1.6'
  # Provider for `commonmarker`, the new GFM lib
  # spec.add_development_dependency 'yard-commonmarker', '~> 0.3.0'

end
