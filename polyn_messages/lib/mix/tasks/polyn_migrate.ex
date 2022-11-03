defmodule Mix.Tasks.Polyn.Migrate do
  @moduledoc """
  Updates JetStream which stream and consumer changes. Also updates the Polyn schema registry

  ```bash
  mix polyn.migrate
  ```
  """
  @shortdoc "Migrate changes to schemas and NATS server"

  use Mix.Task
  require Mix.Generator

  defstruct [:root_dir, :store_name, :conn]

  @conn_name :migrate_gnat

  @impl Mix.Task
  def run(args) do
    shell = Mix.shell()

    {opts, _args} = OptionParser.parse!(args, strict: [dir: :string, store_name: :string])

    args =
      struct(
        __MODULE__,
        Keyword.merge(opts, root_dir: Keyword.get(opts, :dir, File.cwd!()))
        |> Keyword.put(:conn, @conn_name)
      )

    shell.info("Connection to NATS")
    start_nats_connection()

    shell.info("Updating Schemas")

    Polyn.SchemaMigrator.migrate(
      store_name: args.store_name,
      root_dir: args.root_dir,
      conn: args.conn,
      log: &shell.info/1
    )
  end

  defp start_nats_connection do
    connection_settings = Application.get_env(:polyn_messages, :nats_connection_settings)

    # Not using the `Gnat.ConnectionSupervisor` because this is not a long-lived process
    Gnat.start_link(Enum.random(connection_settings), name: @conn_name)
  end
end
