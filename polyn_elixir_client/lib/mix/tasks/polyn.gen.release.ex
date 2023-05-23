defmodule Mix.Tasks.Polyn.Gen.Release do
  @moduledoc """
  Use `mix polyn.gen.release` to generate a new polyn release module for your application
  """
  @shortdoc "Generates a new polyn release file"

  use Mix.Task
  require Mix.Generator

  def run(args) do
    {options, []} = OptionParser.parse!(args, strict: [dir: :string])
    path = Path.join(dir(options), "polyn_release.ex")
    assigns = [mod: module_name(), app: app_name()]

    Mix.Generator.create_file(path, release_file_template(assigns))
  end

  defp dir(options) do
    Keyword.get(options, :dir, Path.join(File.cwd!(), "lib"))
  end

  defp app_name do
    Mix.Project.config() |> Keyword.fetch!(:app)
  end

  defp module_name do
    prefix = app_name() |> Atom.to_string() |> Macro.camelize()
    Module.concat([prefix, Polyn, Release])
  end

  Mix.Generator.embed_template(:release_file, """
  defmodule <%= inspect @mod %> do
    @app <%= inspect @app %>

    def migrate do
      load_app()

      dir = Path.join([:code.priv_dir(@app), "polyn", "migrations"])
      Polyn.Migration.Migrator.run(migrations_dir: dir)
    end

    defp load_app do
      Application.load(@app)
      {:ok, _apps} = Application.ensure_all_started(:polyn)
    end
  end
  """)
end
