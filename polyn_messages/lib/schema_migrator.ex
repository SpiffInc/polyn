defmodule Polyn.SchemaMigrator do
  # Module for migrating JSON schemas for Polyn messages
  @moduledoc false

  alias Jetstream.API.KV

  @store_name "POLYN_SCHEMAS"

  defstruct store_name: @store_name, schema_dir: nil, conn: nil

  def migrate(opts) do
    args =
      struct!(
        __MODULE__,
        Keyword.put_new(opts, :schema_dir, Path.join(File.cwd!(), "message_schemas"))
      )

    get_schema_files(args)
    |> persist_schemas(args)
  end

  defp get_schema_files(%{schema_dir: schema_dir}) do
    cloud_event_schema = get_cloud_event_schema()

    Path.wildcard(schema_dir <> "**/*.json")
    |> Enum.map(fn path ->
      schema =
        decode_schema_file(path)
        |> compose_cloud_event_schema(cloud_event_schema)

      {Path.basename(path, ".json"), schema}
    end)
  end

  # We mix the message schema with a cloud event schema so that there's only one
  # unified schema to validate against
  defp get_cloud_event_schema do
    Application.app_dir(:polyn_messages, "priv/cloud-event-schema.json")
    |> File.read!()
    |> Jason.decode!()
  end

  defp decode_schema_file(path) do
    File.read!(path) |> Jason.decode!()
  end

  defp compose_cloud_event_schema(schema, cloud_event_schema) do
    put_in(cloud_event_schema, ["definitions", "datadef"], schema)
  end

  def persist_schemas(schemas, args) do
    Enum.each(schemas, fn {name, schema} ->
      KV.put_value(args.conn, args.store_name, name, Jason.encode!(schema))
    end)
  end
end
