defmodule Polyn.Migration.MigratorTest do
  use ExUnit.Case, async: true

  alias Jetstream.API.{Consumer, Stream}
  alias Polyn.Connection
  alias Polyn.Migration
  alias Polyn.Migration.Migrator
  import ExUnit.CaptureLog

  @moduletag :tmp_dir
  @common_stream_name "test_stream"
  @common_consumer_name "test_consumer"
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

  # Turning off log because of no migrations found message
  @tag capture_log: true
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

      assert {:ok, info} = Stream.info(Connection.name(), @common_stream_name)
      assert info.config.name == @common_stream_name
    end

    test "limits replicas based on config", context do
      Application.put_env(:polyn, :max_replicas, 1)

      add_migration_file(context.migrations_dir, "1234_create_stream.exs", """
      defmodule ExampleCreateStream do
        import Polyn.Migration

        def change do
          create_stream(name: "#{@common_stream_name}", subjects: ["test_subject"], num_replicas: 5)
        end
      end
      """)

      run(context)

      assert {:ok, info} = Stream.info(Connection.name(), @common_stream_name)
      assert info.config.num_replicas == 1

      Application.delete_env(:polyn, :max_replicas)
    end

    test "adds run migrations to kv bucket", context do
      add_migration_file(context.migrations_dir, "1234_create_stream.exs", """
      defmodule ExampleCreateStream do
        import Polyn.Migration

        def change do
          create_stream(name: "#{@common_stream_name}", subjects: ["test_subject"])
          create_stream(name: "other_stream", subjects: ["other_subject"])
        end
      end
      """)

      run(context)

      assert ["1234"] == Migration.Bucket.already_run_migrations()
      Jetstream.API.Stream.delete(Connection.name(), "other_stream")
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

      %{message: msg} =
        assert_raise(Polyn.Migration.Exception, fn ->
          run(context)
        end)

      assert msg =~
               "Error running migration file 1234_create_stream.exs - \":subjects must be a list of strings\""
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

    test "multiple commands in same migration are in correct order", context do
      add_migration_file(context.migrations_dir, "1234_create_stream.exs", """
      defmodule ExampleCreateStream do
        import Polyn.Migration

        def change do
          create_stream(name: "#{@common_stream_name}", subjects: ["test_subject"])
          delete_stream("#{@common_stream_name}")
        end
      end
      """)

      run(context)

      assert {:error, %{"code" => 404}} = Stream.info(Connection.name(), @common_stream_name)
    end
  end

  describe "consumers" do
    test "adds a migration to create a new consumer", context do
      Stream.create(Connection.name(), %Stream{
        name: @common_stream_name,
        subjects: ["test_subject"]
      })

      add_migration_file(context.migrations_dir, "1234_create_consumer.exs", """
      defmodule ExampleCreateConsumer do
        import Polyn.Migration

        def change do
          create_consumer(
            durable_name: "#{@common_consumer_name}",
            stream_name: "#{@common_stream_name}")
        end
      end
      """)

      run(context)

      assert {:ok, info} =
               Consumer.info(Connection.name(), @common_stream_name, @common_consumer_name)

      assert info.config.durable_name == @common_consumer_name
    end

    test "adds a migration to delete a consumer", context do
      Stream.create(Connection.name(), %Stream{
        name: @common_stream_name,
        subjects: ["test_subject"]
      })

      Consumer.create(Connection.name(), %Consumer{
        durable_name: @common_consumer_name,
        stream_name: @common_stream_name
      })

      add_migration_file(context.migrations_dir, "1234_create_consumer.exs", """
      defmodule ExampleCreateConsumer do
        import Polyn.Migration

        def change do
          delete_consumer(durable_name: "#{@common_consumer_name}", stream_name: "#{@common_stream_name}")
        end
      end
      """)

      run(context)

      assert {:error, %{"code" => 404}} =
               Consumer.info(Connection.name(), @common_stream_name, @common_consumer_name)
    end
  end

  describe "rollback" do
    test "reverse create_stream", context do
      add_migration_file(context.migrations_dir, "1234_create_stream.exs", """
      defmodule ExampleCreateStream do
        import Polyn.Migration

        def change do
          create_stream(name: "#{@common_stream_name}", subjects: ["test_subject"])
        end
      end
      """)

      Migrator.run(migrations_dir: context.migrations_dir, direction: :up)
      Migrator.run(migrations_dir: context.migrations_dir, direction: :down)

      assert {:error, %{"code" => 404}} = Stream.info(Connection.name(), @common_stream_name)
      assert [] == Migration.Bucket.already_run_migrations()
    end
  end

  defp add_migration_file(dir, file_name, contents) do
    File.write!(Path.join(dir, file_name), contents)
  end

  defp run(context) do
    Migrator.run(migrations_dir: context.migrations_dir)
  end
end
