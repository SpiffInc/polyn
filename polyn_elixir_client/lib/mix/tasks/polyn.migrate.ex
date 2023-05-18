defmodule Mix.Tasks.Polyn.Migrate do
  @moduledoc """
  Use `mix polyn.migrate` to make configuration changes to your NATS server.
  """
  @shortdoc "Runs migrations to make modifications to your NATS Server"

  use Mix.Task

  alias Polyn.Migration.Migrator

  def run(args) do
    {:ok, _apps} = Application.ensure_all_started(:polyn)

    :ok = Polyn.Connection.wait_for_connection()

    parse_args(args)
    |> Migrator.run()
  end

  defp parse_args(args) do
    {options, []} = OptionParser.parse!(args, strict: [migrations_dir: :string])

    [
      migrations_dir: Keyword.get(options, :migrations_dir, Migrator.migrations_dir())
    ]
  end
end
