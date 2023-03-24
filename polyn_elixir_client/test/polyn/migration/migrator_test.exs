defmodule Polyn.Migration.MigratorTest do
  use Polyn.ConnCase, async: true

  alias Polyn.Migration
  alias Polyn.Migration.Migrator
  alias Polyn.Connection
  alias Jetstream.API.Stream
  import ExUnit.CaptureLog

  @moduletag :tmp_dir
  @conn_name :migrator_test
  @moduletag with_gnat: @conn_name
  @common_stream_name "test_stream"
  @migration_bucket "POLYN_MIGRATIONS"

  setup context do
    Migration.Bucket.delete()
    Stream.delete(Connection.name(), @common_stream_name)

    migrations_dir = Path.join(context.tmp_dir, "migrations")
    File.mkdir!(migrations_dir)

    # We make the same test module over and over again in a tmp_file so we can ignore the
    # `redefining module MyMigration (current version defined in memory)` warning
    Code.compiler_options(ignore_module_conflict: true)

    Map.put(context, :migrations_dir, migrations_dir)
  end

  test "migrations ignore non .exs files", context do
    File.write!(Path.join(context.migrations_dir, "foo.text"), "foo")
    assert run(context) == :ok
  end

  test "logs when no local migrations found", context do
    assert capture_log(fn ->
             run(context)
           end) =~ "No migrations found at #{context.migrations_dir}"
  end

  test "creates migration bucket if there is none", context do
    assert run(context) == :ok

    assert {:ok, %{config: %{name: "KV_#{@migration_bucket}"}}} = Migration.Bucket.info()
  end

  describe "streams" do
    test "adds a migration to create a new stream", context do
      add_migration_file(context.migrations_dir, "1234_create_stream.exs", """
      defmodule ExampleCreateStream do
        import Polyn.Migration

        def change do
          create_stream(name: "#{@common_stream_name}", subjects: ["test_subject"])
        end
      end
      """)

      run(context)

      # assert {:ok, %{data: data}} = Polyn.MigrationStream.get_last_migration()
      # assert data == "1234"

      assert {:ok, info} = Stream.info(Connection.name(), @common_stream_name)
      assert info.config.name == @common_stream_name
    end

    test "raises if bad config", context do
      add_migration_file(context.migrations_dir, "1234_create_stream.exs", """
      defmodule ExampleCreateStream do
        import Polyn.Migration

        def change do
          create_stream(name: "#{@common_stream_name}", subjects: nil)
        end
      end
      """)

      assert_raise(Polyn.Migration.Exception, fn ->
        run(context)
      end)
    end

    test "does not run already run migrations", context do
      Migration.Bucket.create()
      Migration.Bucket.add_migration("1234")

      add_migration_file(context.migrations_dir, "1234_create_stream.exs", """
      defmodule ExampleCreateStream do
        import Polyn.Migration

        def change do
          create_stream(name: "#{@common_stream_name}", subjects: ["test_subject"])
        end
      end
      """)

      run(context)

      assert {:error, %{"code" => 404}} = Stream.info(Connection.name(), @common_stream_name)
    end

    test "adds a migration to update a stream", context do
      Stream.create(Connection.name(), %Stream{
        name: @common_stream_name,
        subjects: ["test_subject"]
      })

      add_migration_file(context.migrations_dir, "1234_update_stream.exs", """
      defmodule ExampleCreateStream do
        import Polyn.Migration

        def change do
          update_stream(name: "#{@common_stream_name}", description: "my test stream")
        end
      end
      """)

      run(context)

      assert {:ok, info} = Stream.info(Connection.name(), @common_stream_name)
      assert info.config.description == "my test stream"
    end

    test "update raises if stream does not exist", context do
      add_migration_file(context.migrations_dir, "1234_update_stream.exs", """
      defmodule ExampleCreateStream do
        import Polyn.Migration

        def change do
          update_stream(name: "#{@common_stream_name}", description: "my test stream")
        end
      end
      """)

      assert_raise(Polyn.Migration.Exception, fn ->
        run(context)
      end)
    end

    test "migrations happen in correct order", context do
      add_migration_file(context.migrations_dir, "222_update_stream.exs", """
      defmodule ExampleSecondStream do
        import Polyn.Migration

        def change do
          update_stream(name: "#{@common_stream_name}", description: "my test stream")
        end
      end
      """)

      add_migration_file(context.migrations_dir, "111_create_stream.exs", """
      defmodule ExampleFirstStream do
        import Polyn.Migration

        def change do
          create_stream(name: "#{@common_stream_name}", subjects: ["first_subject"])
        end
      end
      """)

      assert :ok = run(context)

      assert {:ok, info} = Stream.info(Connection.name(), @common_stream_name)
      assert info.config.description == "my test stream"
    end

    test "adds a migration to delete a stream", context do
      Stream.create(Connection.name(), %Stream{
        name: @common_stream_name,
        subjects: ["test_subject"]
      })

      add_migration_file(context.migrations_dir, "1234_delete_stream.exs", """
      defmodule ExampleDeleteStream do
        import Polyn.Migration

        def change do
          delete_stream("#{@common_stream_name}")
        end
      end
      """)

      run(context)

      assert {:error, %{"code" => 404}} = Stream.info(Connection.name(), @common_stream_name)
    end
  end

  defp add_migration_file(dir, file_name, contents) do
    File.write!(Path.join(dir, file_name), contents)
  end

  defp run(context) do
    Migrator.run(migrations_dir: context.migrations_dir)
  end
end
