defmodule Mix.Tasks.Polyn.Rollback do
  @moduledoc """
  Use `mix polyn.rollback` to rollback a change to your NATS server.
  """
  @shortdoc "Rolls back a migration to your NATS Server"

  use Mix.Task

  alias Polyn.Migration.Migrator

  def run(args) do
    {:ok, _apps} = Application.ensure_all_started(:polyn)

    parse_args(args)
    |> Keyword.put(:direction, :down)
    |> Migrator.run()
  end

  defp parse_args(args) do
    {options, []} = OptionParser.parse!(args, strict: [migrations_dir: :string])

    [
      migrations_dir: Keyword.get(options, :migrations_dir, Migrator.migrations_dir())
    ]
  end
end
