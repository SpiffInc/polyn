# frozen_string_literal: true

module Polyn
  class Cli
    ##
    # Configuration data for Polyn::Cli
    class Configuration
      attr_reader :polyn_env, :nats_servers, :nats_credentials

      def initialize
        @polyn_env        = ENV["POLYN_ENV"] || "development"
        @nats_servers     = ENV["NATS_SERVERS"] || "localhost:4222"
        @nats_credentials = ENV["NATS_CREDENTIALS"] || ""
        @nats_ca_file     = ENV["NATS_CA_FILE"] || ""
      end
    end
  end
end
