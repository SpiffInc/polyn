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

  defstruct [:base_dir]

  @impl Mix.Task
  def run(args) do
    {opts, _args} = OptionParser.parse!(args, strict: [dir: :string, store_name: :string])

    args =
      struct!(__MODULE__,
        base_dir: Keyword.get(opts, :dir, File.cwd!()),
        store_name: opts[:store_name]
      )
  end
end
