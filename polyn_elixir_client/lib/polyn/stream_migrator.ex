defmodule Polyn.StreamMigrator do
  # Manages the creation and updating of streams and consumers that
  # an application owns
  @moduledoc false

  require Logger

  alias __MODULE__.Stream

  def run(conn, dir) do
    get_config_files(%{conn: conn, dir: dir})
    |> compile_config_files()
    |> get_configs()
    |> execute_configs()
  end

  defp get_config_files(%{dir: dir} = state) do
    files =
      case File.ls(dir) do
        {:ok, []} ->
          Logger.info("No stream configurations found at #{dir}")
          []

        {:ok, files} ->
          Enum.filter(files, &is_elixir_script?/1)

        {:error, _reason} ->
          Logger.info("No stream configurations found at #{dir}")
          []
      end

    Map.put(state, :files, files)
  end

  defp is_elixir_script?(file_name) do
    String.ends_with?(file_name, ".exs")
  end

  defp compile_config_files(%{dir: dir, files: files} = state) do
    modules =
      Enum.map(files, fn file_name ->
        [{module, _content}] = Code.compile_file(Path.join(dir, file_name))
        module
      end)

    Map.put(state, :config_modules, modules)
  end

  defp get_configs(%{config_modules: modules} = state) do
    configs = Enum.map(modules, & &1.configure)
    Map.put(state, :configs, configs)
  end

  defp execute_configs(%{conn: conn, configs: configs}) do
    Enum.each(configs, &execute_config(conn, &1))
  end

  defp execute_config(conn, {:stream, fields}) do
    Stream.change(conn, fields)
  end
end
