defmodule Mix.Tasks.Polyn.MigrateTest do
  use Polyn.ConnCase, async: true

  @conn_name :polyn_migrate_test
  @store_name "POLYN_MIGRATE_TEST_STORE"
  @moduletag with_gnat: @conn_name
  @moduletag :tmp_dir

  alias Jetstream.API.KV

  setup do
    {:ok, _info} = KV.create_bucket(@conn_name, @store_name)

    on_exit(fn ->
      cleanup(fn pid ->
        :ok = KV.delete_bucket(pid, @store_name)
      end)
    end)

    :ok
  end

  test "adds schema to the store", %{tmp_dir: tmp_dir} do
    add_schema_file(tmp_dir, "app.widgets.v1", %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"}
      }
    })

    Mix.Task.rerun("polyn.migrate", ["--dir", tmp_dir, "--store-name", @store_name])

    schema = get_schema("app.widgets.v1")

    assert schema["definitions"]["datadef"] == %{
             "type" => "object",
             "properties" => %{
               "name" => %{"type" => "string"}
             }
           }
  end

  defp add_schema_file(tmp_dir, path, contents) do
    Path.join([tmp_dir, "message_schemas", Path.dirname(path)]) |> File.mkdir_p!()
    File.write!(Path.join([tmp_dir, "message_schemas", path <> ".json"]), Jason.encode!(contents))
  end

  defp get_schema(name) do
    KV.get_value(@conn_name, @store_name, name) |> Jason.decode!()
  end
end
