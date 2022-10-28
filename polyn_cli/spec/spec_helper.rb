# frozen_string_literal: true

require "polyn/cli"
require "tmpdir"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

RSpec.shared_context :tmp_dir do
  around do |example|
    Dir.mktmpdir("rspec-") do |dir|
      @tmp_dir = dir
      example.run
    end
  end

  attr_reader :tmp_dir
end
