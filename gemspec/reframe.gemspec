# coding: utf-8

# because of symlink trickery :)
prog = File.basename($0)
# puts "Here I am! #{$0}"
# puts __FILE__
gemspec = File.basename(__FILE__)
lib = case gemspec
when '.gemspec'
	File.expand_path('../lib', __FILE__) # bundle exec rake ? why is there a binstub ?
else
	File.expand_path('../../lib', __FILE__)
end
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
# p $LOAD_PATH
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
  spec.add_runtime_dependency "sqlite3"

	# separate test and devel and test&devel ?
  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "codecov"
  spec.add_development_dependency "bundler-audit"
  spec.add_development_dependency "ripper-tags"
  spec.add_development_dependency "pry"
	# spec.add_development_dependency "standalone-migrations"
end
