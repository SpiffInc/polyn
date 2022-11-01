defmodule Polyn.SchemaMigratorTest do
  use Polyn.ConnCase, async: true

  alias Jetstream.API.KV
  alias Polyn.SchemaMigrator

  @conn_name :schema_migrator_test
  @store_name "SCHEMA_MIGRATOR_TEST_STORE"
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

  test "adds schema to the store", %{tmp_dir: tmp_dir} do
    add_schema_file(tmp_dir, "app.widgets.v1", %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"}
      }
    })

    SchemaMigrator.migrate(store_name: @store_name, schema_dir: tmp_dir, conn: @conn_name)

    schema = get_schema("app.widgets.v1")

    assert schema["definitions"]["datadef"] == %{
             "type" => "object",
             "properties" => %{
               "name" => %{"type" => "string"}
             }
           }
  end

  test "adds schema to the store from subdirectories", %{tmp_dir: tmp_dir} do
    add_schema_file(tmp_dir, "foo-dir/app.widgets.v1", %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"}
      }
    })

    SchemaMigrator.migrate(store_name: @store_name, schema_dir: tmp_dir, conn: @conn_name)

    schema = get_schema("app.widgets.v1")

    assert schema["definitions"]["datadef"] == %{
             "type" => "object",
             "properties" => %{
               "name" => %{"type" => "string"}
             }
           }
  end

  test "invalid json schema raises", %{tmp_dir: tmp_dir} do
    add_schema_file(tmp_dir, "app.widgets.v1", "foo")

    %{message: message} =
      assert_raise(Polyn.MigrationException, fn ->
        SchemaMigrator.migrate(store_name: @store_name, schema_dir: tmp_dir, conn: @conn_name)
      end)

    assert message =~ "for event, app.widgets.v1"
    assert message =~ "no function clause matching in ExJsonSchema.Schema.resolve/2"
  end

  test "invalid file name raises", %{tmp_dir: tmp_dir} do
    add_schema_file(tmp_dir, "app widgets v1", %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"}
      }
    })

    assert_raise(Polyn.NamingException, fn ->
      SchemaMigrator.migrate(store_name: @store_name, schema_dir: tmp_dir, conn: @conn_name)
    end)
  end

  defp add_schema_file(tmp_dir, path, contents) do
    Path.join(tmp_dir, Path.dirname(path)) |> File.mkdir_p!()
    File.write!(Path.join([tmp_dir, path <> ".json"]), Jason.encode!(contents))
  end

  defp get_schema(name) do
    KV.get_value(@conn_name, @store_name, name) |> Jason.decode!()
  end
end
