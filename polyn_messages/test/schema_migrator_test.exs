defmodule Polyn.SchemaMigratorTest do
  use Polyn.ConnCase, async: true

  alias Jetstream.API.{KV, Stream}
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

  test "raises if schema files are deleted", %{tmp_dir: tmp_dir} do
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

    %{message: message} =
      assert_raise(Polyn.CompatibilityException, fn ->
        SchemaMigrator.migrate(store_name: @store_name, root_dir: tmp_dir, conn: @conn_name)
      end)

    assert message =~ "Cannot find a schema file for app.widgets.v1"
  end

  describe "stream setup" do
    setup do
      Stream.delete(@conn_name, "APP_WIDGETS_V1")
      :ok
    end

    test "adds stream for the schema", %{tmp_dir: tmp_dir} do
      add_schema_file(tmp_dir, "app.widgets.v1", %{
        "type" => "object",
        "properties" => %{
          "name" => %{"type" => "string"}
        }
      })

      SchemaMigrator.migrate(store_name: @store_name, root_dir: tmp_dir, conn: @conn_name)

      assert {:ok,
              %{
                config: %{
                  name: "APP_WIDGETS_V1",
                  subjects: ["app.widgets.v1"],
                  description: nil,
                  max_age: 0,
                  max_bytes: -1,
                  max_consumers: -1,
                  max_msg_size: -1,
                  max_msgs: -1,
                  max_msgs_per_subject: -1,
                  num_replicas: 1,
                  storage: :file
                }
              }} = Stream.info(@conn_name, "APP_WIDGETS_V1")
    end

    test "schema description is stream description", %{tmp_dir: tmp_dir} do
      add_schema_file(tmp_dir, "app.widgets.v1", %{
        "description" => "something about widgets",
        "type" => "object",
        "properties" => %{
          "name" => %{"type" => "string"}
        }
      })

      SchemaMigrator.migrate(store_name: @store_name, root_dir: tmp_dir, conn: @conn_name)

      assert {:ok, %{config: %{description: "something about widgets"}}} =
               Stream.info(@conn_name, "APP_WIDGETS_V1")
    end

    test "schema with `identity_key` property has token subject", %{tmp_dir: tmp_dir} do
      add_schema_file(tmp_dir, "app.widgets.v1", %{
        "identity" => "id",
        "type" => "object",
        "properties" => %{
          "id" => %{"type" => "string"},
          "name" => %{"type" => "string"}
        }
      })

      SchemaMigrator.migrate(store_name: @store_name, root_dir: tmp_dir, conn: @conn_name)

      assert {:ok, %{config: %{subjects: ["app.widgets.v1.*"]}}} =
               Stream.info(@conn_name, "APP_WIDGETS_V1")
    end
  end

  defp add_schema_file(tmp_dir, path, contents) do
    Path.join([tmp_dir, "message_schemas", Path.dirname(path)]) |> File.mkdir_p!()
    File.write!(Path.join([tmp_dir, "message_schemas", path <> ".json"]), Jason.encode!(contents))
  end

  defp get_schema(name) do
    KV.get_value(@conn_name, @store_name, name) |> Jason.decode!()
  end
end
