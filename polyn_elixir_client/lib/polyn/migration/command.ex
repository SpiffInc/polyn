defmodule Polyn.Migration.Command do
  # Where we execute the commands
  @moduledoc false

  alias Polyn.Connection

  @doc "Actually apply the change to the server"
  def execute({id, :create_stream, opts}, migrator_state) do
    stream = struct(Jetstream.API.Stream, opts)

    case Jetstream.API.Stream.create(Connection.name(), stream) do
      {:error, reason} ->
        raise_migration_exception(id, migrator_state, reason)

      success ->
        success
    end
  end

  def execute({id, :update_stream, opts}, migrator_state) do
    stream = update_stream_config(opts)

    case Jetstream.API.Stream.update(Connection.name(), stream) do
      {:error, reason} ->
        raise_migration_exception(id, migrator_state, reason)

      success ->
        success
    end
  end

  def execute({id, :delete_stream, stream_name}, migrator_state) do
    case Jetstream.API.Stream.delete(Connection.name(), stream_name) do
      {:error, reason} ->
        raise_migration_exception(id, migrator_state, reason)

      success ->
        success
    end
  end

  def execute({id, :create_consumer, opts}, migrator_state) do
    consumer = struct(Jetstream.API.Consumer, opts)

    case Jetstream.API.Consumer.create(Connection.name(), consumer) do
      {:error, reason} ->
        raise_migration_exception(id, migrator_state, reason)

      success ->
        success
    end
  end

  def execute(command, _migrator_state) do
    raise Polyn.Migration.Exception,
          "Command #{inspect(command)} not recognized"
  end

  # We only want to require that changed attributes are passed in the migration.
  # The %Stream{} struct requires certain fields that may already be set. We want
  # to get those from the existing config
  defp update_stream_config(opts) do
    info =
      case Jetstream.API.Stream.info(Connection.name(), opts[:name]) do
        {:ok, info} -> info
        {:error, reason} -> raise Polyn.Migration.Exception, inspect(reason)
      end

    Map.merge(info.config, Map.new(opts))
  end

  defp raise_migration_exception(id, state, reason) do
    msg = get_migration_file(id, state) |> migration_message(reason)
    raise Polyn.Migration.Exception, msg
  end

  defp get_migration_file(migration_id, state) do
    Enum.find(state.migration_files, &String.contains?(&1, migration_id))
  end

  defp migration_message(file, reason) do
    "Error running migration file #{file} - #{inspect(reason)}"
  end
end
