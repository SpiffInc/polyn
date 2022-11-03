defmodule Polyn.SchemaMigrator do
  # Module for migrating JSON schemas for Polyn messages
  @moduledoc false

  require Logger
  alias Jetstream.API.KV

  @store_name "POLYN_SCHEMAS"
  @schema_dir "message_schemas"

  defstruct store_name: @store_name,
            schema_dir: nil,
            conn: nil,
            paths: nil,
            schemas: nil,
            log: nil

  @type migrate_option ::
          {:store_name, binary()} | {:root_dir, binary()} | {:conn, Gnat.t()} | {:log, fun()}

  @spec migrate(opts :: [migrate_option()]) :: :ok
  def migrate(opts) do
    args =
      struct(
        __MODULE__,
        Keyword.merge(opts, schema_dir: get_schema_dir(opts), store_name: get_store_name(opts))
        |> Keyword.put_new(:log, &Logger.info/1)
      )

    args.log.("Loading events into the Polyn schema registry from #{args.schema_dir}")

    schema_file_paths(args)
    |> validate_uniqueness!()
    |> read_schema_files()
    |> persist_schemas()
    |> delete_missing_schemas()

    :ok
  end

  defp get_schema_dir(opts) do
    Keyword.fetch!(opts, :root_dir) |> Path.join(@schema_dir)
  end

  defp get_store_name(opts) do
    opts[:store_name] || @store_name
  end

  defp schema_file_paths(%{schema_dir: schema_dir} = args) do
    Map.put(args, :paths, Path.wildcard(schema_dir <> "/**/*.json"))
  end

  defp validate_uniqueness!(%{paths: paths} = args) do
    duplicates =
      Enum.group_by(paths, &Path.basename(&1, ".json"))
      |> Enum.filter(fn {_message_name, paths} -> Enum.count(paths) > 1 end)
      |> Enum.map(fn {message_name, paths} ->
        "#{message_name} -> \n#{format_duplicate_paths(paths, args)}"
      end)

    unless Enum.empty?(duplicates) do
      msg =
        [
          "There can only be one of each message schema. The following message names were duplicated:"
          | duplicates
        ]
        |> Enum.join("\n")

      raise Polyn.MigrationException, msg
    end

    args
  end

  defp format_duplicate_paths(paths, %{schema_dir: schema_dir} = args) do
    Enum.map_join(paths, "\n", fn path -> "\t" <> relative_path(path, args) end)
  end

  defp relative_path(path, args) do
    Path.relative_to(path, args.schema_dir)
  end

  defp read_schema_files(%{paths: paths} = args) do
    cloud_event_schema = get_cloud_event_schema()

    schemas =
      Enum.reduce(paths, %{}, fn path, acc ->
        args.log.("Reading schema from #{relative_path(path, args)}")
        name = Path.basename(path, ".json")
        Polyn.Naming.validate_message_name!(name)

        schema =
          decode_schema_file(path)
          |> validate_schema(name)
          |> compose_cloud_event_schema(cloud_event_schema)

        Map.put(acc, name, schema)
      end)

    Map.put(args, :schemas, schemas)
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

  defp validate_schema(schema, name) do
    ExJsonSchema.Schema.resolve(schema)
    schema
  rescue
    e ->
      reraise Polyn.MigrationException,
              "Invalid JSON Schema document for event, #{name}\n" <>
                "Schema: #{inspect(schema)}\n" <>
                "Rescued Error: #{e.__struct__.message(e)}\n",
              __STACKTRACE__
  end

  defp persist_schemas(%{schemas: schemas} = args) do
    Enum.each(schemas, fn {name, schema} ->
      KV.put_value(args.conn, args.store_name, name, Jason.encode!(schema))
    end)

    args
  end

  defp delete_missing_schemas(%{schemas: schemas} = args) do
    schema_files = Map.keys(schemas) |> MapSet.new()

    load_all_schemas(args)
    |> Map.keys()
    |> MapSet.new()
    |> MapSet.difference(schema_files)
    |> Enum.each(fn missing_schema ->
      args.log.("Deleting schema #{missing_schema}")
      KV.delete_key(args.conn, args.store_name, missing_schema)
    end)

    args
  end

  defp load_all_schemas(%{conn: conn, store_name: store_name}) do
    case KV.contents(conn, store_name) do
      {:ok, schemas} ->
        schemas

      {:error, error} ->
        raise Polyn.MigrationException,
              "Could not load schemas from store #{inspect(store_name)}.\n#{inspect(error)}"
    end
  end
end