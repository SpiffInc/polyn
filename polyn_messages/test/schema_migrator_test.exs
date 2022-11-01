defmodule Polyn.SchemaMigratorTest do
  use Polyn.ConnCase, async: true

  alias Polyn.SchemaMigrator

  @conn_name :schema_migrator_test
  @store_name "SCHEMA_MIGRATOR_TEST_STORE"
  @moduletag :tmp_dir
  @moduletag with_gnat: @conn_name

  setup do
    Jetstream.API.KV.create_bucket(@conn_name, @store_name)

    cleanup(fn pid ->
      Jetstream.API.KV.delete_bucket(pid, @store_name)
    end)

    :ok
  end

  test "adds schema to the store", %{tmp_dir: tmp_dir} do
    # SchemaMigrator.migrate()
    add_schema_file(tmp_dir, "app.widgets.v1", %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"}
      }
    })
  end

  defp add_schema_file(tmp_dir, path, contents) do
    Path.join(tmp_dir, Path.dirname(path)) |> File.mkdir_p!()
    File.write!(Path.join([tmp_dir, path <> ".json"]), Jason.encode!(contents))
  end
end
