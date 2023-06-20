defmodule Polyn.Migration.Migrator do
  @moduledoc """
  Manages the creation and updating of streams and consumers that
  an application owns
  """

  require Logger

  alias Polyn.Migration
  alias Polyn.Migration.Runner

  @typedoc """
  Tuple of {command_name, command_options}
  """
  @type command :: {atom(), any()}

  @typedoc """
  * `:direction` - Which direction to migrate
  * `:migrations_function` - The function to run inside the migration module (e.g. `change`, `up`, `down`)
  * `:migrations_dir` - Location of migration files
  * `:running_migration_id` - The timestamp/id of the migration file being run. Taken from the beginning of the file name
  * `:migration_bucket_info` - The Stream info for the migration KV bucket
  * `:runner` - Process for keeping commands to run
  * `:migration_files` - The file names of migration files
  * `:migration_modules` - A list of tuples with the migration id and module code
  * `:already_run_migrations` - Migrations we've determined have already been executed on the server
  * `:commands` - map of migration_id and commands to run
  """
  @type t :: %__MODULE__{
          direction: :up | :down,
          migration_function: :change | :up | :down,
          migrations_dir: binary(),
          running_migration_id: non_neg_integer() | nil,
          migration_bucket_info: Jetstream.API.Stream.info() | nil,
          runner: pid() | nil,
          migration_files: [binary()],
          migration_modules: [{integer(), module()}],
          commands: %{binary() => [command()]},
          already_run_migrations: [binary()]
        }

  # Holds the state of the migration as we move through migration steps
  defstruct [
    :direction,
    :migration_function,
    :running_migration_id,
    :migrations_dir,
    :migration_bucket_info,
    :runner,
    migration_files: [],
    migration_modules: [],
    commands: %{},
    already_run_migrations: []
  ]

  def new(opts \\ []) do
    opts =
      Keyword.put_new(opts, :migrations_dir, migrations_dir())
      |> Keyword.put_new(:direction, :up)

    struct!(__MODULE__, opts)
  end

  @doc """
  Path of migration files
  """
  def migrations_dir do
    Path.join([File.cwd!(), "priv", "polyn", "migrations"])
  end

  @doc """
  Entry point for starting migrations

  ## Options

  * `:migrations_dir` - Location of migration files
  * `:direction` - `:up` or `:down` to run migrations in a specific direction. Defaults to `:up`
  """
  @spec run(opts :: [{:migrations_dir, binary()} | {:direction, :down | :up}]) :: :ok
  @spec run() :: :ok
  def run(opts \\ []) do
    # The Gnat ConnectionSupervisor startup is non-blocking, so we
    # need to make sure the connection to NATS is established
    # before we attempt to migrate
    :ok = Polyn.Connection.wait_for_connection()

    new(opts)
    |> get_migration_bucket_info()
    |> create_migration_bucket()
    |> get_already_run_migrations()
    |> get_migration_files()
    |> filter_applicable_files()
    |> compile_migration_files()
    |> get_migration_commands()
    |> execute_commands()

    :ok
  end

  defp get_migration_bucket_info(state) do
    case Migration.Bucket.info() do
      {:ok, info} -> Map.put(state, :migration_bucket_info, info)
      _ -> state
    end
  end

  defp create_migration_bucket(%{migration_bucket_info: nil} = state) do
    case Migration.Bucket.create() do
      {:ok, info} -> Map.put(state, :migration_bucket_info, info)
      {:error, reason} -> raise Polyn.Migration.Exception, inspect(reason)
    end
  end

  defp create_migration_bucket(state), do: state

  defp get_already_run_migrations(state) do
    migrations = Migration.Bucket.already_run_migrations()
    Map.put(state, :already_run_migrations, migrations)
  end

  defp get_migration_files(%{migrations_dir: migrations_dir} = state) do
    files =
      case File.ls(migrations_dir) do
        {:ok, []} ->
          Logger.info("No migrations found at #{migrations_dir}")
          []

        {:ok, files} ->
          files
          |> Enum.filter(&is_elixir_script?/1)

        {:error, reason} ->
          Logger.info("No migrations found at #{migrations_dir}. #{inspect(reason)}")
          []
      end

    Map.put(state, :migration_files, files)
  end

  defp is_elixir_script?(file_name) do
    String.ends_with?(file_name, ".exs")
  end

  defp filter_applicable_files(%{direction: :up} = state) do
    %{already_run_migrations: already_run_migrations, migration_files: files} = state

    files =
      Enum.reject(files, fn file ->
        id = extract_migration_id(file)
        Enum.member?(already_run_migrations, id)
      end)

    Map.put(state, :migration_files, files)
  end

  defp filter_applicable_files(%{direction: :down} = state) do
    %{already_run_migrations: already_run_migrations, migration_files: files} = state

    last_run = List.last(already_run_migrations)

    last_run_file =
      Enum.find(files, fn file ->
        extract_migration_id(file) == last_run
      end)

    Map.put(state, :migration_files, [last_run_file])
  end

  defp compile_migration_files(%{migration_files: files, migrations_dir: migrations_dir} = state) do
    modules =
      Enum.map(files, fn file_name ->
        id = extract_migration_id(file_name)
        [{module, _content}] = Code.compile_file(Path.join(migrations_dir, file_name))
        {id, module}
      end)

    Map.put(state, :migration_modules, modules)
  end

  defp extract_migration_id(file_name) do
    [id | _] = String.split(file_name, "_")
    id
  end

  defp get_migration_commands(state) do
    {:ok, pid} = Runner.start_link(state)
    Process.put(:polyn_migration_runner, pid)

    Enum.each(state.migration_modules, fn {id, module} ->
      Runner.update_running_migration_id(pid, id)
      func = migration_function(module, state)
      Runner.update_migration_function(pid, func)
      apply(module, func, [])
    end)

    state = Runner.get_state(pid) |> Map.put(:running_migration_id, nil)
    Runner.stop(pid)
    state
  end

  defp migration_function(module, %{direction: direction}) do
    cond do
      function_exported?(module, direction, 0) ->
        direction

      function_exported?(module, :change, 0) ->
        :change

      true ->
        raise Polyn.Migration.Exception,
              "Migration module #{module} does not define a #{inspect(direction)}/0 or change/0 function"
    end
  end

  defp execute_commands(state) do
    sort_commands(state)
    |> Enum.each(fn {id, subcommands} ->
      Enum.each(subcommands, &Migration.Command.execute(id, &1, state))
      # We only want to update the migration id in the bucket once we know
      # all its commands were successfully executed
      update_migration_bucket(state, id)
    end)

    state
  end

  defp sort_commands(%{direction: :down, commands: commands}) do
    sort_commands(%{commands: commands})
    |> Enum.reverse()
  end

  defp sort_commands(%{commands: commands}) do
    Enum.sort_by(commands, fn {migration_id, _subcommands} -> migration_id end)
  end

  defp update_migration_bucket(%{direction: :down}, id) do
    Migration.Bucket.remove_migration(id)
  end

  defp update_migration_bucket(_state, id) do
    Migration.Bucket.add_migration(id)
  end
end
