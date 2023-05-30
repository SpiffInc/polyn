defmodule Polyn.Migration.Command do
  # Where we execute the commands
  @moduledoc false

  alias Jetstream.API.{Consumer, Stream}
  alias Polyn.Connection
  alias Polyn.Migration

  @doc "Actually apply the change to the server"
  def execute({id, :create_stream, opts}, migrator_state) do
    opts = maybe_limit_replicas(opts)
    stream = struct(Stream, opts)

    Stream.create(Connection.name(), stream)
    |> handle_execute_result(id, migrator_state)
  end

  def execute({id, :update_stream, opts}, migrator_state) do
    opts = maybe_limit_replicas(opts)
    stream = update_stream_config(opts)

    Stream.update(Connection.name(), stream)
    |> handle_execute_result(id, migrator_state)
  end

  def execute({id, :delete_stream, stream_name}, migrator_state) do
    Stream.delete(Connection.name(), stream_name)
    |> handle_execute_result(id, migrator_state)
  end

  def execute({id, :create_consumer, opts}, migrator_state) do
    consumer = struct(Consumer, opts)

    Consumer.create(Connection.name(), consumer)
    |> handle_execute_result(id, migrator_state)
  end

  def execute({id, :delete_consumer, opts}, migrator_state) do
    stream_name = Keyword.get(opts, :stream_name)
    durable_name = Keyword.get(opts, :durable_name)

    Consumer.delete(Connection.name(), stream_name, durable_name)
    |> handle_execute_result(id, migrator_state)
  end

  def execute(command, _migrator_state) do
    raise Migration.Exception,
          "Command #{inspect(command)} not recognized"
  end

  defp handle_execute_result({:error, reason}, id, migrator_state) do
    raise_migration_exception(id, migrator_state, reason)
  end

  defp handle_execute_result(success, _id, _migrator_state), do: success

  # We only want to require that changed attributes are passed in the migration.
  # The %Stream{} struct requires certain fields that may already be set. We want
  # to get those from the existing config
  defp update_stream_config(opts) do
    info =
      case Jetstream.API.Stream.info(Connection.name(), opts[:name]) do
        {:ok, info} -> info
        {:error, reason} -> raise Migration.Exception, inspect(reason)
      end

    Map.merge(info.config, Map.new(opts))
  end

  # In dev/test environments we likely will have less servers than in prod.
  # If there's a config to limit replicas in a given environment we want
  # to enforce that here for the migration
  defp maybe_limit_replicas(opts) do
    num_replicas = Keyword.get(opts, :num_replicas)

    case {max_replicas(), num_replicas} do
      {nil, _num} -> opts
      {_max, nil} -> opts
      {max, num} when num > max -> Keyword.put(opts, :num_replicas, max)
      _ -> opts
    end
  end

  defp max_replicas do
    Application.get_env(:polyn, :max_replicas)
  end

  defp raise_migration_exception(id, state, reason) do
    msg = get_migration_file(id, state) |> migration_message(reason)
    raise Migration.Exception, msg
  end

  defp get_migration_file(migration_id, state) do
    Enum.find(state.migration_files, &String.contains?(&1, migration_id))
  end

  defp migration_message(file, reason) do
    "Error running migration file #{file} - #{inspect(reason)}"
  end
end
