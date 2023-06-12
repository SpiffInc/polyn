defmodule Polyn.Migration.Runner do
  # A way to update the migration state without exposing it to
  # developers creating migration files. This will allow Migration
  # functions to update the state without developers needing to be
  # aware of it.
  @moduledoc false
  use Agent

  @spec start_link(Polyn.Migration.Migrator.t()) :: Agent.on_start()
  def start_link(state) do
    Agent.start_link(fn -> state end)
  end

  def stop(pid) do
    Agent.stop(pid)
  end

  @doc "Add a new command to execute to the state"
  def add_command(pid, command_name, command_opts) do
    running_migration_id = get_running_migration_id(pid)

    state = get_state(pid)

    new_subcommand = build_subcommand(state, running_migration_id, command_name, command_opts)

    case new_subcommand do
      {:ok, new_subcommand} ->
        subcommands = Map.get(state.commands, running_migration_id, [])
        subcommands = concat_subcommand(state, subcommands, new_subcommand)
        commands = Map.put(state.commands, running_migration_id, subcommands)
        update_commands(pid, commands)

      {:error, message} ->
        raise Polyn.Migration.Exception, message
    end
  end

  defp build_subcommand(
         %{direction: :down, migration_function: :change} = state,
         migration_id,
         command_name,
         opts
       ) do
    case reverse(command_name, opts) do
      {command_name, opts} ->
        {:ok, {command_name, opts}}

      :error ->
        file = get_migration_file(migration_id, state)

        {:error,
         "Migration command #{inspect(command_name)} in file #{file} can't be reversed. " <>
           "Please implement the `up/0` and `down/0` explicitly in your migration module."}
    end
  end

  defp build_subcommand(_state, _migration_id, command_name, opts) do
    {:ok, {command_name, opts}}
  end

  defp concat_subcommand(
         %{direction: :down, migration_function: :change},
         subcommands,
         new_subcommand
       ) do
    # We want the commands to be executed in reverse order when rolling back a `change` function
    [new_subcommand | subcommands]
  end

  defp concat_subcommand(_state, subcommands, new_subcommand) do
    Enum.concat(subcommands, [new_subcommand])
  end

  defp update_commands(pid, commands) do
    Agent.update(pid, fn state ->
      Map.put(state, :commands, commands)
    end)
  end

  @doc "Update the state to know the id of the migration running"
  def update_running_migration_id(pid, id) do
    Agent.update(pid, fn state ->
      Map.put(state, :running_migration_id, id)
    end)
  end

  @doc "Update the state to know which migration function is being executed based on direction"
  def update_migration_function(pid, func) do
    Agent.update(pid, fn state ->
      Map.put(state, :migration_function, func)
    end)
  end

  def get_running_migration_id(pid) do
    get_state(pid).running_migration_id
  end

  def get_state(pid) do
    Agent.get(pid, fn state -> state end)
  end

  defp reverse(:create_stream, opts) do
    {:delete_stream, Keyword.get(opts, :name)}
  end

  defp reverse(:create_consumer, opts) do
    {:delete_consumer, Keyword.take(opts, [:durable_name, :stream_name])}
  end

  defp reverse(_command, _opts), do: :error

  defp get_migration_file(migration_id, state) do
    Enum.find(state.migration_files, &String.contains?(&1, migration_id))
  end
end
