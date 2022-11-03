defmodule Mix.Tasks.Polyn.Delete.SchemaTest do
  use Polyn.ConnCase, async: true

  alias Jetstream.API.KV

  @conn_name :schema_delete_test
  @store_name "SCHEMA_DELETE_TEST_STORE"
  @moduletag :tmp_dir
  @moduletag with_gnat: @conn_name

  setup do
    {:ok, _info} = KV.create_bucket(@conn_name, @store_name)

    on_exit(fn ->
      cleanup(fn pid ->
        :ok = KV.delete_bucket(pid, @store_name)
      end)
    end)

    :ok
  end

  test "deletes a message schema", %{tmp_dir: tmp_dir} do
    schema = %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"}
      }
    }

    KV.put_value(@conn_name, @store_name, "app.widgets.v1", Jason.encode!(schema))

    add_schema_file(tmp_dir, "app.widgets.v1", schema)

    Mix.Task.rerun("polyn.delete.schema", [
      "app.widgets.v1",
      "--dir",
      tmp_dir,
      "--store-name",
      @store_name
    ])

    refute File.exists?(Path.join([tmp_dir, "message_schemas", "app.widgets.v1.json"]))

    refute get_schema("app.widgets.v1")
  end

  defp add_schema_file(tmp_dir, path, contents) do
    Path.join([tmp_dir, "message_schemas", Path.dirname(path)]) |> File.mkdir_p!()
    File.write!(Path.join([tmp_dir, "message_schemas", path <> ".json"]), Jason.encode!(contents))
  end

  defp get_schema(name) do
    KV.get_value(@conn_name, @store_name, name)
  end
end
