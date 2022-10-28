# frozen_string_literal: true

module Polyn
  class Cli
    ##
    # Loads the JSON schmea into the event registry.
    class SchemaLoader
      include Thor::Actions

      STORE_NAME = "POLYN_SCHEMAS"

      ##
      # Loads the events from the event repository into the Polyn event registry.
      # @return [Bool]
      def self.load(cli)
        new(cli).load_events
      end

      def initialize(thor, **opts)
        @thor               = thor
        @client             = NATS.connect(Polyn::Cli.configuration.nats_servers).jetstream
        @store_name         = opts.fetch(:store_name, STORE_NAME)
        @bucket             = client.key_value(@store_name)
        @cloud_event_schema = Polyn::Cli::CloudEvent.to_h.freeze
        @events_dir         = opts.fetch(:events_dir, File.join(Dir.pwd, "events"))
        @events             = {}
        @existing_events    = {}
      end

      def load_events
        thor.say "Loading events into the Polyn event registry from '#{events_dir}'"
        read_events
        load_existing_events

        events.each do |name, event|
          bucket.put(name, JSON.generate(event))
        end

        delete_missing_events

        true
      end

      private

      attr_reader :thor,
        :events,
        :client,
        :bucket,
        :cloud_event_schema,
        :events_dir,
        :store_name,
        :existing_events

      def read_events
        event_files = Dir.glob(File.join(events_dir, "/**/*.json"))
        validate_unique_event_types!(event_files)

        event_files.each do |event_file|
          thor.say "Loading 'event #{event_file}'"
          data_schema = JSON.parse(File.read(event_file))
          event_type  = File.basename(event_file, ".json")
          validate_schema!(event_type, data_schema)
          Polyn::Cli::Naming.validate_event_type!(event_type)
          schema      = compose_cloud_event(data_schema)

          events[event_type] = schema
        end
      end

      def validate_unique_event_types!(event_files)
        duplicates = find_duplicates(event_files)
        unless duplicates.empty?
          messages = duplicates.reduce([]) do |memo, (event_type, files)|
            memo << [event_type, *files].join("\n")
          end
          message  = [
            "There can only be one of each event type. The following events were duplicated:",
            *messages,
          ].join("\n")
          raise Polyn::Cli::ValidationError, message
        end
      end

      def find_duplicates(event_files)
        event_types = event_files.group_by do |event_file|
          File.basename(event_file, ".json")
        end
        event_types.each_with_object({}) do |(event_type, files), hash|
          hash[event_type] = files if files.length > 1
          hash
        end
      end

      def validate_schema!(event_type, schema)
        JSONSchemer.schema(schema)
      rescue StandardError => e
        raise Polyn::Cli::ValidationError,
          "Invalid JSON Schema document for event #{event_type}\n#{e.message}\n"\
          "#{JSON.pretty_generate(schema)}"
      end

      def compose_cloud_event(event_schema)
        cloud_event_schema.merge({
          "definitions" => cloud_event_schema["definitions"].merge({
            "datadef" => event_schema,
          }),
        })
      end

      def load_existing_events
        sub = client.subscribe("#{key_prefix}.>")

        loop do
          msg                                                     = sub.next_msg
          existing_events[msg.subject.gsub("#{key_prefix}.", "")] = msg.data unless msg.data.empty?
        # A timeout is the only mechanism given to indicate there are no
        # more messages
        rescue NATS::IO::Timeout
          break
        end
        sub.unsubscribe
      end

      def key_prefix
        "$KV.#{store_name}"
      end

      def delete_missing_events
        missing_events = existing_events.keys - events.keys
        missing_events.each do |event|
          thor.say "Deleting event #{event}"
          bucket.delete(event)
        end
      end
    end
  end
end
