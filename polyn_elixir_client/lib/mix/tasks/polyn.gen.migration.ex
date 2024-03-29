defmodule Mix.Tasks.Polyn.Gen.Migration do
  @moduledoc """
  Use `mix polyn.gen.migration <name>` to generate a new migration module for your application

  The `<name>` argument should be the snake_cased name representing the change the migration will make.

  The generated migration filename will be prefixed with the current timestamp in UTC which is used for versioning and ordering.
  """
  @shortdoc "Generates a new polyn migration file"

  use Mix.Task

  alias Polyn.Migration

  def run(args) do
    parse_args(args)
    |> Migration.Generator.run()
  end

  defp parse_args([]) do
    Mix.raise("you must supply the snake_cased name of the migration")
  end

  defp parse_args(args) do
    {options, [name]} = OptionParser.parse!(args, strict: [dir: :string])

    %{
      name: name,
      dir: Keyword.get(options, :dir, Migration.Migrator.migrations_dir())
    }
  end
end
