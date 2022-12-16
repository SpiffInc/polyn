# frozen_string_literal: true

module Polyn
  class Cli
    ##
    # Generates a new NATS Consumer configuration for a stream
    class ConsumerGenerator < Thor::Group
      include Thor::Actions

      desc "Generates a new NATS Consumer configuration for a stream"

      argument :stream_name, required: true, desc: "The name of the stream to consume events from"
      argument :destination_name, required: true,
        desc: "The name of the application, service, or component consuming the event"
      argument :message_name, required: true, desc: "The name of the message being consumed"
      class_option :dir, default: Dir.getwd

      source_root File.join(File.expand_path(__dir__), "../templates")

      def check_names
        Polyn::Cli::Naming.validate_stream_name!(stream_name)
        Polyn::Cli::Naming.validate_destination_name!(destination_name)
        Polyn::Cli::Naming.validate_message_name!(message_name)
      end

      def check_stream_existance
        return if File.exist?(file_path)

        raise Polyn::Cli::Error,
          "You must first create a stream configuration with "\
          "`polyn gen:stream #{format_stream_name}`"
      end

      def check_schema
        return if File.exist?(File.join(options.dir, "schemas", "#{message_name}.json"))

        raise Polyn::Cli::Error,
          "You must first create a schema with `polyn gen:schema #{message_name}`"
      end

      def format_stream_name
        @stream_name = stream_name.upcase
      end

      def consumer_name
        dest = Polyn::Cli::Naming.colon_to_underscore(destination_name)
        dest = Polyn::Cli::Naming.dot_to_underscore(dest)
        name = Polyn::Cli::Naming.dot_to_underscore(message_name)
        "#{dest}_#{name}"
      end

      def file_name
        @file_name ||= "tf/#{stream_name.downcase}.tf"
      end

      def file_path
        File.join(options.dir, file_name)
      end

      def create
        say "Creating new consumer config #{consumer_name} for stream #{stream_name}"
        consumer_config = <<~TF

          resource "jetstream_consumer" "#{consumer_name}" {
            stream_id = jetstream_stream.#{stream_name}.id
            durable_name = "#{consumer_name}"
            deliver_all = true
            filter_subject = "#{message_name}"
            sample_freq = 100
          }
        TF
        append_to_file(file_path, consumer_config)
      end
    end
  end
end
