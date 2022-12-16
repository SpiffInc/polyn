# frozen_string_literal: true

require "thor"
require "dotenv"
require "json_schemer"
require "polyn/cli/configuration"
require "polyn/cli/consumer_generator"
require "polyn/cli/naming"
require "polyn/cli/schema_generator"
require "polyn/cli/stream_generator"
require "polyn/cli/cloud_event"
require "polyn/cli/schema_loader"
require "polyn/cli/version"
require "json"
require "nats/client"

Dotenv.load

module Polyn
  ##
  # CLI for Polyn for configuring NATS server
  class Cli
    ##
    # Proxy to Thor start
    def self.start(args)
      Commands.start(args)
    end

    class Error < StandardError; end
    class ValidationError < Error; end

    ##
    # Configuration information for Polyn
    def self.configuration
      @configuration ||= Polyn::Cli::Configuration.new
    end

    ##
    # Thor commands for the CLI. Subclassed so other classes can be in the CLI namespace
    class Commands < Thor
      include Thor::Actions

      source_root File.join(File.expand_path(__dir__), "templates")

      # https://github.com/rails/thor/wiki/Making-An-Executable
      def self.exit_on_failure?
        true
      end

      method_option :dir, default: Dir.getwd
      desc "init", "initializes a Polyn event repository"
      def init
        say "Initializing Polyn event repository"
        directory "tf", File.join(options.dir, "tf")
        directory "schemas", File.join(options.dir, "schemas")
        template "docker-compose.yml", File.join(options.dir, "docker-compose.yml")
        template "Dockerfile", File.join(options.dir, "Dockerfile")
        template ".dockerignore", File.join(options.dir, ".dockerignore")
        template ".gitignore", File.join(options.dir, ".gitignore")
        template "README.md", File.join(options.dir, "README.md")
        template "Gemfile", File.join(options.dir, "Gemfile")
        run tf_init
        say "Initializing git"
        inside options.dir do
          run "git init"
        end
        say "Repository initialized"
      end

      method_option :dir, default: Dir.getwd
      desc "tf_init", "Initializes Terraform for configuration"
      def tf_init
        terraform_root = File.join(options.dir, "tf")
        say "Initializing Terraform"
        inside terraform_root do
          # In a development environment we want developers to work with their own local
          # .tfstate rather than one configured in a remote `backend` intended for
          # production use.
          # https://www.terraform.io/language/settings/backends/configuration
          #
          # Terraform assumes only one backend will be configured and there's no path
          # to switch between local and remote. There's also no way to dynamically load
          # modules. https://github.com/hashicorp/terraform/issues/1439
          # Instead we'll copy a backend config to the terraform root if we're in a production
          # environment
          if polyn_env == "production"
            add_remote_backend(terraform_root) { run "terraform init" }
          else
            run "terraform init"
          end
        end
      end

      desc "up", "updates the JetStream streams and consumers, as well the Polyn event registry"
      def up
        terraform_root = File.join(Dir.getwd, "tf")
        # We only want to run nats in the docker container if
        # the developer isn't already running nats themselves locally
        if polyn_env == "development" && !nats_running?
          say "Starting NATS"
          run "docker compose up --detach"
        end

        say "Updating JetStream configuration"
        inside "tf" do
          if polyn_env == "production"
            add_remote_backend(terraform_root) { run tf_apply }
          else
            run tf_apply
          end
        end

        say "Updating Polyn event registry"
        Polyn::Cli::SchemaLoader.new(self).load_events
      end

      private

      def polyn_env
        Polyn::Cli.configuration.polyn_env
      end

      def nats_servers
        Polyn::Cli.configuration.nats_servers
      end

      def nats_credentials
        Polyn::Cli.configuration.nats_credentials
      end

      def nats_ca_file
        Polyn::Cli.configuration.nats_ca_file
      end

      def tf_apply
        if polyn_env == "development"
          %(terraform apply -auto-approve -input=false -var "jetstream_servers=#{nats_servers}")
        else
          "terraform apply -auto-approve -input=false "\
            "-var \"jetstream_servers=#{nats_servers}\" "\
            "-var \"nats_credentials=#{nats_credentials}\" " \
            "-var \"nats_ca_file=#{nats_ca_file}\" " \
            "-var \"polyn_env=production\""
        end
      end

      def nats_running?
        # Uses lsof command to look up a process id. Will return `true` if it finds one
        system("lsof -i TCP:4222 -t")
      end

      def add_remote_backend(tf_root)
        copy_file File.join(tf_root, "remote_state_config/backend.tf"), "backend.tf"
        yield
      # We always want to remove the backend.tf file even if there's an error
      # this way you don't get into a weird state when testing locally
      ensure
        remove_file File.join(tf_root, "backend.tf")
      end

      register(Polyn::Cli::SchemaGenerator, "gen:schema", "gen:schema EVENT_TYPE",
        "Generates a new JSON Schema file for an event")
      register(Polyn::Cli::StreamGenerator, "gen:stream", "gen:stream NAME",
        "Generates a new stream configuration with boilerplate")
      register(Polyn::Cli::ConsumerGenerator, "gen:consumer",
        "gen:consumer STREAM_NAME DESTINATION_NAME EVENT_TYPE",
        "Generates a new NATS Consumer configuration with boilerplate")
    end
  end
end
