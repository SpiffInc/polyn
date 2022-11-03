defmodule Polyn.SchemaMigrator.Stream do
  # Functions for managing the NATS Stream associated with a schema
  @moduledoc false

  alias Jetstream.API.Stream
  alias Polyn.Messages.CloudEvent
  alias Polyn.SchemaMigrator

  @stream_not_found_code 10_059

  @doc """
  Create a new NATS JetStream Stream for a message schema
  """
  def create_stream(name, schema, %SchemaMigrator{} = migrator) do
    stream = %Stream{
      name: Polyn.Naming.stream_name(name),
      subjects: [subject(name, schema)],
      description: schema_description(schema)
    }

    unless stream_exists?(stream, migrator) do
      migrator.log.("Creating stream #{stream.name}")
      Stream.create(migrator.conn, stream)
    end
  end

  defp schema_description(schema) do
    CloudEvent.data_schema(schema)["description"]
  end

  defp subject(name, schema) do
    case CloudEvent.data_schema(schema)["identity"] do
      nil ->
        name

      _identity ->
        "#{name}.*"
    end
  end

  defp stream_exists?(%Stream{} = stream, migrator) do
    case Stream.info(migrator.conn, stream.name) do
      {:ok, _info} ->
        true

      {:error, %{"err_code" => @stream_not_found_code}} ->
        false

      {:error, error} ->
        raise Polyn.MigrationException, inspect(error)
    end
  end
end
