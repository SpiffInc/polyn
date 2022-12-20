# frozen_string_literal: true

module Polyn
  class Cli
    ##
    # Loads the JSON schema into the schema registry.
    class SchemaLoader
      include Thor::Actions

      STORE_NAME = "POLYN_SCHEMAS"

      ##
      # Loads the schemas from the schema repository into the Polyn schema registry.
      # @return [Bool]
      def self.load(cli)
        new(cli).load_schemas
      end

      def initialize(thor, **opts)
        @thor               = thor
        @client             = connect
        @store_name         = opts.fetch(:store_name, STORE_NAME)
        @bucket             = client.key_value(@store_name)
        @schemas_dir        = opts.fetch(:schemas_dir, File.join(Dir.pwd, "schemas"))
        @schemas            = {}
        @existing_schemas   = {}
      end

      def load_schemas
        thor.say "Loading schemas into the Polyn schema registry from '#{schemas_dir}'"
        read_schemas
        load_existing_schemas

        schemas.each do |name, schema|
          bucket.put(name, JSON.generate(schema))
        end

        delete_missing_schemas

        true
      end

      private

      attr_reader :thor,
        :schemas,
        :client,
        :bucket,
        :schemas_dir,
        :store_name,
        :existing_schemas

      def connect
        opts = {
          max_reconnect_attempts: 5,
          reconnect_time_wait:    0.5,
          servers:                Polyn::Cli.configuration.nats_servers.split(","),
        }

        if Polyn::Cli.configuration.nats_tls
          opts[:tls] = { context: ::OpenSSL::SSL::SSLContext.new(:TLSv1_2) }
        end

        NATS.connect(opts).jetstream
      end

      def read_schemas
        schema_files = Dir.glob(File.join(schemas_dir, "/**/*.json"))
        validate_unique_schema_names!(schema_files)

        schema_files.each do |schema_file|
          thor.say "Loading 'schema #{schema_file}'"
          schema      = JSON.parse(File.read(schema_file))
          schema_name = File.basename(schema_file, ".json")
          validate_schema!(schema_name, schema)
          Polyn::Cli::Naming.validate_message_name!(schema_name)

          schemas[schema_name] = schema
        end
      end

      def validate_unique_schema_names!(schema_files)
        duplicates = find_duplicates(schema_files)
        return if duplicates.empty?

        messages = duplicates.reduce([]) do |memo, (schema_name, files)|
          memo << [schema_name, *files].join("\n")
        end
        message  = [
          "There can only be one of each schema name. The following schemas were duplicated:",
          *messages,
        ].join("\n")
        raise Polyn::Cli::ValidationError, message
      end

      def find_duplicates(schema_files)
        schema_names = schema_files.group_by do |schema_file|
          File.basename(schema_file, ".json")
        end
        schema_names.each_with_object({}) do |(schema_name, files), hash|
          hash[schema_name] = files if files.length > 1
          hash
        end
      end

      def validate_schema!(schema_name, schema)
        JSONSchemer.schema(schema)
      rescue StandardError => e
        raise Polyn::Cli::ValidationError,
          "Invalid JSON Schema document for event #{schema_name}\n#{e.message}\n"\
          "#{JSON.pretty_generate(schema)}"
      end

      def load_existing_schemas
        sub = client.subscribe("#{key_prefix}.>")

        loop do
          msg                                                      = sub.next_msg
          existing_schemas[msg.subject.gsub("#{key_prefix}.", "")] = msg.data unless msg.data.empty?
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

      def delete_missing_schemas
        missing_schemas = existing_schemas.keys - schemas.keys
        missing_schemas.each do |schema|
          thor.say "Deleting schema #{schema}"
          bucket.delete(schema)
        end
      end
    end
  end
end
