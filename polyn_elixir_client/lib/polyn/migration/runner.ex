defmodule Polyn.Migration.Runner do
  # A way to update the migration state without exposing it to
  # developers creating migration files. This will allow Migration
  # functions to update the state without developers needing to be
  # aware of it.
  @moduledoc false
  use Agent

  def start_link(state) do
    Agent.start_link(fn -> state end)
  end

  def stop(pid) do
    Agent.stop(pid)
  end

  @doc "Add a new command to execute to the state"
  def add_command(pid, command) do
    running_migration_id = get_running_migration_id(pid)

    Agent.update(pid, fn state ->
      commands = Enum.concat(state.commands, [{running_migration_id, command}])
      Map.put(state, :commands, commands)
    end)
  end

  @doc "Update the state to know the id of the migration running"
  def update_running_migration_id(pid, id) do
    Agent.update(pid, fn state ->
      Map.put(state, :running_migration_id, id)
    end)
  end

  def get_running_migration_id(pid) do
    get_state(pid).running_migration_id
  end

  def get_state(pid) do
    Agent.get(pid, fn state -> state end)
  end
end
