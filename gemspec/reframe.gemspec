# coding: utf-8
lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'reframe/version'

Gem::Specification.new do |spec|
  spec.name          = "reframe"
  spec.version       = ReFrame::VERSION
  spec.authors       = ["Shugo Maeda", "Anthony Durity"]
	spec.email         = ["shugo@ruby-lang.org", "a.durity@umail.ucc.ie"]

  spec.summary       = "A semantic document editor written in Ruby"
  spec.description   = "ReFrame – markdown meets semantic web triples"
  spec.homepage      = "https://github.com/igravious/reframe"
	spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.3'

  spec.add_runtime_dependency "curses", ">= 1.2.2"
  spec.add_runtime_dependency "unicode-display_width", "~> 1.1"
  spec.add_runtime_dependency "clipboard", "~> 1.1"
  spec.add_runtime_dependency "fiddley", ">= 0.0.5"
  spec.add_runtime_dependency "editorconfig"
  spec.add_runtime_dependency "rouge"

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "codecov"
  spec.add_development_dependency "bundler-audit"
  spec.add_development_dependency "ripper-tags"
  spec.add_development_dependency "pry"
end
