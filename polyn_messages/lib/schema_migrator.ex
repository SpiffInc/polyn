defmodule Polyn.SchemaMigrator do
  # Module for migrating JSON schemas for Polyn messages
  @moduledoc false

  require Logger
  alias Jetstream.API.{KV, Stream}
  alias Polyn.Messages.CloudEvent

  @schema_dir "message_schemas"
  @stream_not_found_code 10059

  defstruct store_name: nil,
            schema_dir: nil,
            conn: nil,
            paths: nil,
            schemas: nil,
            old_schemas: nil,
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

    schema_file_paths(args)
    |> validate_uniqueness!()
    |> read_schema_files()
    |> load_all_schemas()
    |> validate_compatibility!()
    |> persist_schemas()

    :ok
  end

  defp get_schema_dir(opts) do
    Keyword.fetch!(opts, :root_dir) |> Path.join(@schema_dir)
  end

  defp get_store_name(opts) do
    opts[:store_name] || Polyn.Messages.default_schema_store()
  end

  defp schema_file_paths(%{schema_dir: schema_dir} = args) do
    args.log.("Finding schema files in #{args.schema_dir}")
    Map.put(args, :paths, Path.wildcard(schema_dir <> "/**/*.json"))
  end

  defp validate_uniqueness!(%{paths: paths} = args) do
    args.log.("Validating schema uniqueness")

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

  defp format_duplicate_paths(paths, args) do
    Enum.map_join(paths, "\n", fn path -> "\t" <> relative_path(path, args) end)
  end

  defp relative_path(path, args) do
    Path.relative_to(path, args.schema_dir)
  end

  defp read_schema_files(%{paths: paths} = args) do
    cloud_event_schema = CloudEvent.get_schema()

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

  defp decode_schema_file(path) do
    File.read!(path) |> Jason.decode!()
  end

  # We mix the message schema with a cloud event schema so that there's only one
  # unified schema to validate against
  defp compose_cloud_event_schema(schema, cloud_event_schema) do
    CloudEvent.merge_schema(cloud_event_schema, schema)
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

  defp load_all_schemas(%{conn: conn, store_name: store_name} = args) do
    args.log.("Loading current schemas from registry")

    case KV.contents(conn, store_name) do
      {:ok, schemas} ->
        Map.put(args, :old_schemas, schemas)

      {:error, error} ->
        raise Polyn.MigrationException,
              "Could not load schemas from store #{inspect(store_name)}.\n#{inspect(error)}"
    end
  end

  defp validate_compatibility!(args) do
    args.log.("Validating schema compatibility")
    errors = validate_none_deleted(args)

    unless Enum.empty?(errors) do
      raise Polyn.CompatibilityException, Enum.join(errors, "\n")
    end

    args
  end

  defp validate_none_deleted(%{schemas: new_schemas, old_schemas: old_schemas}) do
    schema_files = Map.keys(new_schemas) |> MapSet.new()

    Map.keys(old_schemas)
    |> MapSet.new()
    |> MapSet.difference(schema_files)
    |> Enum.map(fn missing_schema ->
      "Cannot find a schema file for #{missing_schema}. Deleting schemas is a breaking change. " <>
        "To delete a schema, ensure that no services are depending on it and then use the `mix polyn.delete.schema` " <>
        "task to delete it"
    end)
  end

  defp persist_schemas(%{schemas: schemas} = args) do
    Enum.each(schemas, fn {name, schema} ->
      add_to_registry(name, schema, args)
      create_stream(name, schema, args)
    end)

    args
  end

  defp add_to_registry(name, schema, args) do
    args.log.("Saving schema #{name} in the registry")
    KV.put_value(args.conn, args.store_name, name, Jason.encode!(schema))
  end

  defp create_stream(name, schema, args) do
    description = CloudEvent.get_data_schema(schema)["description"]

    stream = %Stream{
      name: Polyn.Naming.stream_name(name),
      subjects: [name],
      description: description
    }

    unless stream_exists?(stream, args) do
      args.log.("Creating stream #{stream.name}")
      Stream.create(args.conn, stream)
    end
  end

  defp stream_exists?(%Stream{} = stream, args) do
    case Stream.info(args.conn, stream.name) do
      {:ok, _info} ->
        true

      {:error, %{"err_code" => @stream_not_found_code}} ->
        false

      {:error, error} ->
        raise Polyn.MigrationException, inspect(error)
    end
  end
end
