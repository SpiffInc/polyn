# frozen_string_literal: true

require_relative "lib/polyn/cli/version"

Gem::Specification.new do |spec|
  spec.name          = "polyn-cli"
  spec.version       = Polyn::Cli::VERSION
  spec.authors       = ["Jarod", "Brandyn Bennett"]
  spec.email         = ["jarod.reid@spiff.com", "brandyn.bennett@spiff.com"]

  spec.summary               = "CLI for the Polyn service framework"
  spec.description           = "CLI for the Polyn service framework"
  spec.homepage              = "https://github.com/SpiffInc/polyn/tree/main/polyn_cli"
  spec.license               = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "dotenv",    "~> 2.7.6"
  spec.add_dependency "json_schemer", "~> 0.2"
  spec.add_dependency "nats-pure", "~> 2.0.0"
  spec.add_dependency "thor",      "~> 1.2.0"
end
