# frozen_string_literal: true

require_relative "lib/wampproto/version"

Gem::Specification.new do |spec|
  spec.name = "wampproto"
  spec.version = Wampproto::VERSION
  spec.authors = ["Ismail Akram"]
  spec.email = ["rubyonrails3@gmail.com"]

  spec.summary = "Sans-IO WAMP protocol implementation in Ruby"
  spec.description = "Sans-IO WAMP protocol implementation in Ruby"
  spec.homepage = "https://github.com/xconnio/wampproto.rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "cbor", "~> 0.5.9.8"
  spec.add_dependency "ed25519", "~> 1.3"
  spec.add_dependency "msgpack", "~> 1.7.2"
end
