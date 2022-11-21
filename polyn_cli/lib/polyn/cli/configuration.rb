# frozen_string_literal: true

module Polyn
  class Cli
    ##
    # Configuration data for Polyn::Cli
    class Configuration
      attr_reader :polyn_env, :nats_servers, :nats_credentials, :nats_ca_file, :nats_tls

      def initialize
        @polyn_env        = ENV["POLYN_ENV"] || "development"
        @nats_servers     = ENV["NATS_SERVERS"] || "nats://127.0.0.1:4222"
        @nats_credentials = ENV["NATS_CREDENTIALS"] || ""
        @nats_ca_file     = ENV["NATS_CA_FILE"] || ""
        @nats_tls         = ENV["NATS_TLS"] || false
      end
    end
  end
end
