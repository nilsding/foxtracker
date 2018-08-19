# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "foxtracker/version"

Gem::Specification.new do |spec|
  spec.name          = "foxtracker"
  spec.version       = Foxtracker::VERSION
  spec.authors       = ["Georg Gadinger"]
  spec.email         = ["nilsding@nilsding.org"]

  spec.summary       = "a parser for tracker music formats"
  spec.description   = "Foxtracker is a parser for tracker music formats.  Right now it only supports XM (FastTracker II) modules.  Support for more formats is to be done."
  spec.homepage      = "https://github.com/nilsding/foxtracker"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "dry-struct", "~> 0.5"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rt_rubocop_defaults", "~> 1.0"
  spec.add_development_dependency "rubocop", "~> 0.58"
end
