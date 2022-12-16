# frozen_string_literal: true

module Polyn
  class Cli
    ##
    # Generates a new JSON Schema file for an event
    class SchemaGenerator < Thor::Group
      include Thor::Actions

      desc "Generates a new JSON Schema file for an event"

      argument :message_name, required: true
      class_option :dir, default: Dir.getwd

      source_root File.join(File.expand_path(__dir__), "../templates")

      def name
        @name ||= message_name.split("/").last
      end

      def subdir
        @subdir ||= begin
          split = message_name.split("/") - [name]
          split.join("/")
        end
      end

      def check_name
        Polyn::Cli::Naming.validate_message_name!(name)
      end

      def file_name
        @file_name ||= File.join(subdir, "#{name}.json")
      end

      def schema_id
        Polyn::Cli::Naming.dot_to_colon(name)
      end

      def create
        say "Creating new schema for #{file_name}"
        template "generators/schema.json", File.join(options.dir, "schemas/#{file_name}")
      end
    end
  end
end
