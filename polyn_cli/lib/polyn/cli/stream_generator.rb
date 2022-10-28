# frozen_string_literal: true

module Polyn
  class Cli
    ##
    # Generates a new Stream configuration file for terraform
    class StreamGenerator < Thor::Group
      include Thor::Actions

      desc "Generates a new stream configuration with boilerplate"

      argument :name, required: true
      class_option :dir, default: Dir.getwd

      source_root File.join(File.expand_path(__dir__), "../templates")

      def check_name
        Polyn::Cli::Naming.validate_stream_name!(name)
      end

      def file_name
        @file_name ||= name.downcase
      end

      def stream_name
        @stream_name ||= Polyn::Cli::Naming.format_stream_name(name)
      end

      def create
        say "Creating new stream config #{stream_name}"
        template "generators/stream.tf", File.join(options.dir, "tf/#{file_name}.tf")
      end
    end
  end
end
