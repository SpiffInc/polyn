defmodule Mix.Tasks.Polyn.Gen.Release do
  @moduledoc """
  Use `mix polyn.gen.release` to generate a new polyn release module for your application
  """
  @shortdoc "Generates a new polyn release file"

  use Mix.Task
  require Mix.Generator

  def run(args) do
    {options, []} = OptionParser.parse!(args, strict: [dir: :string])
    path = Path.join([dir(options), Atom.to_string(app_name()), "release.ex"])
    assigns = [mod: module_name(), app: app_name()]

    if File.exists?(path) do
      check_existing(path)
    else
      Mix.Generator.create_file(path, release_file_template(assigns))
    end

    inject_into_existing(path)
  end

  defp dir(options) do
    Keyword.get(options, :dir, Path.join(File.cwd!(), "lib"))
  end

  defp app_name do
    Mix.Project.config() |> Keyword.fetch!(:app)
  end

  defp module_name do
    prefix = app_name() |> Atom.to_string() |> Macro.camelize()
    Module.concat([prefix, Release])
  end

  defp check_existing(path) do
    unless prompt_allow_injection(path) do
      System.halt()
    end
  end

  defp prompt_allow_injection(path) do
    Mix.shell().yes?(
      "#{path} already exists. Would you like to inject Polyn release functions into it?"
    )
  end

  defp inject_into_existing(path) do
    file = File.read!(path)

    lines =
      String.trim_trailing(file)
      |> String.trim_trailing("end")
      |> String.split(["\n", "\r\n"])

    lines = List.insert_at(lines, first_private_func_index(lines), polyn_migrate_text())

    injected = Enum.join(lines, "\n") <> "end\n"
    File.write!(path, injected)
  end

  defp first_private_func_index(lines) do
    result =
      Enum.find_index(lines, fn line ->
        String.contains?(line, "defp ")
      end)

    # Use the very end of the file if there are no private functions
    case result do
      nil -> -1
      index -> index
    end
  end

  Mix.Generator.embed_template(:release_file, """
  defmodule <%= inspect @mod %> do
    @app <%= inspect @app %>

    defp load_app do
      Application.load(@app)
    end
  end
  """)

  Mix.Generator.embed_text(
    :polyn_migrate,
    """
      def polyn_migrate do
        load_app()
        {:ok, _apps} = Application.ensure_all_started(:polyn)

        dir = Path.join([:code.priv_dir(@app), "polyn", "migrations"])
        Polyn.Migration.Migrator.run(migrations_dir: dir)
      end
    """
  )
end
