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

    SchemaMigrator.migrate(store_name: @store_name, root_dir: tmp_dir, conn: @conn_name)

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

    SchemaMigrator.migrate(store_name: @store_name, root_dir: tmp_dir, conn: @conn_name)

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
        SchemaMigrator.migrate(store_name: @store_name, root_dir: tmp_dir, conn: @conn_name)
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
      SchemaMigrator.migrate(store_name: @store_name, root_dir: tmp_dir, conn: @conn_name)
    end)
  end

  test "non-json docs are ignored", %{tmp_dir: tmp_dir} do
    File.write!(Path.join(tmp_dir, "foo.png"), "foo")

    assert :ok =
             SchemaMigrator.migrate(
               store_name: @store_name,
               root_dir: tmp_dir,
               conn: @conn_name
             )
  end

  test "raises if two duplicate message names exist in different subdirectories", %{
    tmp_dir: tmp_dir
  } do
    add_schema_file(tmp_dir, "foo-dir/app.widgets.v1", %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"}
      }
    })

    add_schema_file(tmp_dir, "bar-dir/app.widgets.v1", %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"}
      }
    })

    %{message: message} =
      assert_raise(Polyn.MigrationException, fn ->
        SchemaMigrator.migrate(store_name: @store_name, root_dir: tmp_dir, conn: @conn_name)
      end)

    assert message =~ "The following message names were duplicated:"
    assert message =~ "foo-dir/app.widgets.v1"
    # Only showing the relative path for clarity
    refute message =~ tmp_dir
  end

  test "removes deleted schema files from kv store", %{tmp_dir: tmp_dir} do
    # Adding value to kv store with no matching file
    KV.put_value(
      @conn_name,
      @store_name,
      "app.widgets.v1",
      Jason.encode!(%{
        "type" => "object",
        "properties" => %{
          "name" => %{"type" => "string"}
        }
      })
    )

    SchemaMigrator.migrate(store_name: @store_name, root_dir: tmp_dir, conn: @conn_name)

    refute KV.get_value(@conn_name, @store_name, "app.widgets.v1")
  end

  defp add_schema_file(tmp_dir, path, contents) do
    Path.join([tmp_dir, "message_schemas", Path.dirname(path)]) |> File.mkdir_p!()
    File.write!(Path.join([tmp_dir, "message_schemas", path <> ".json"]), Jason.encode!(contents))
  end

  defp get_schema(name) do
    KV.get_value(@conn_name, @store_name, name) |> Jason.decode!()
  end
end
