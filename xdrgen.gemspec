# frozen_string_literal: true

require_relative "lib/xdrgen/version"

Gem::Specification.new do |spec|
  spec.name = "xdrgen"
  spec.version = Xdrgen::VERSION
  spec.authors = ["Scott Fleckenstein"]
  spec.email = ["scott@stellar.org"]
  spec.summary = "An XDR code generator"
  spec.homepage = "http://github.com/stellar/xdrgen"
  spec.license = "ISC"

  spec.files = `git ls-files -z`.split("\x0")
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.5.0"

  spec.add_dependency "activesupport", ">= 5.0.0", "< 7.0"
  spec.add_dependency "memoist", "~> 0.11"
  spec.add_dependency "slop", ">= 3.4.0", "< 5.0"
  spec.add_dependency "treetop", "~> 1.5"
end
