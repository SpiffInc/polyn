# frozen_string_literal: true

module Polyn
  class Cli
    ##
    # Generates a new JSON Schema file for an event
    class SchemaGenerator < Thor::Group
      include Thor::Actions

      desc "Generates a new JSON Schema file for an event"

      argument :event_type, required: true
      class_option :dir, default: Dir.getwd

      source_root File.join(File.expand_path(__dir__), "../templates")

      def type
        @type ||= event_type.split("/").last
      end

      def subdir
        @subdir ||= begin
          split = event_type.split("/") - [type]
          split.join("/")
        end
      end

      def check_name
        Polyn::Cli::Naming.validate_message_name!(type)
      end

      def file_name
        @file_name ||= File.join(subdir, "#{type}.json")
      end

      def schema_id
        Polyn::Cli::Naming.dot_to_colon(type)
      end

      def create
        say "Creating new schema for #{file_name}"
        template "generators/schema.json", File.join(options.dir, "events/#{file_name}")
      end
    end
  end
end
