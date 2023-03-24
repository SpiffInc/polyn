defmodule Polyn.Migration.Migrator do
  # Manages the creation and updating of streams and consumers that
  # an application owns
  @moduledoc false

  require Logger

  alias Polyn.Migration
  alias Polyn.Migration.Runner

  @typedoc """
  * `:migrations_dir` - Location of migration files
  * `:running_migration_id` - The timestamp/id of the migration file being run. Taken from the beginning of the file name
  * `:migration_bucket_info` - The Stream info for the migration KV bucket
  * `:migration_files` - The file names of migration files
  * `:migration_modules` - A list of tuples with the migration id and module code
  * `:already_run_migrations` - Migrations we've determined have already been executed on the server
  """
  @type t :: %__MODULE__{
          migrations_dir: binary(),
          running_migration_id: non_neg_integer() | nil,
          migration_bucket_info: Jetstream.API.Stream.info() | nil,
          migration_files: list(binary()),
          migration_modules: list({integer(), module()}),
          commands: list({integer(), tuple()}),
          already_run_migrations: list(binary())
        }

  # Holds the state of the migration as we move through migration steps
  defstruct [
    :running_migration_id,
    :migrations_dir,
    :migration_bucket_info,
    migration_files: [],
    migration_modules: [],
    commands: [],
    already_run_migrations: []
  ]

  def new(opts \\ []) do
    opts = Keyword.put_new(opts, :migrations_dir, migrations_dir())

    struct!(__MODULE__, opts)
  end

  @doc """
  Path of migration files
  """
  def migrations_dir do
    Path.join(File.cwd!(), "/priv/polyn/migrations")
  end

  def run(opts \\ []) do
    new(opts)
    |> get_migration_bucket_info()
    |> create_migration_bucket()
    |> get_already_run_migrations()
    |> get_migration_files()
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
          |> filter_already_ran(state)
          |> Enum.sort_by(&extract_migration_id/1)

        {:error, reason} ->
          Logger.info("No migrations found at #{migrations_dir}. #{inspect(reason)}")
          []
      end

    Map.put(state, :migration_files, files)
  end

  defp is_elixir_script?(file_name) do
    String.ends_with?(file_name, ".exs")
  end

  defp filter_already_ran(files, %{already_run_migrations: already_run_migrations}) do
    Enum.reject(files, fn file ->
      id = extract_migration_id(file)
      Enum.member?(already_run_migrations, id)
    end)
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
      module.change()
    end)

    state = Runner.get_state(pid)
    Runner.stop(pid)

    state
  end

  defp execute_commands(%{commands: commands} = state) do
    # Gather commmands by migration file so they are executed in order
    Enum.group_by(commands, &elem(&1, 0))
    |> Enum.sort_by(fn {key, _val} -> key end)
    |> Enum.each(fn {_id, commands} ->
      Enum.each(commands, &Polyn.Migration.Command.execute/1)
      # We only want to put the migration id into the stream once we know
      # it was successfully executed
      # MigrationStream.add_migration(id)
    end)

    state
  end
end
