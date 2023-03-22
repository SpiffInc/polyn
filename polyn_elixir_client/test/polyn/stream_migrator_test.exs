defmodule Polyn.StreamMigratorTest do
  use Polyn.ConnCase, async: true

  alias Polyn.StreamMigrator
  alias Jetstream.API.Stream

  @moduletag :tmp_dir
  @conn_name :stream_migrator_test
  @moduletag with_gnat: @conn_name

  setup do
    # We make the same test module over and over again in a tmp_file so we can ignore the
    # `redefining module MyStreamConfig (current version defined in memory)` warning
    Code.compiler_options(ignore_module_conflict: true)
    :ok
  end

  test "makes a new stream", %{tmp_dir: tmp_dir} do
    Stream.delete(@conn_name, "MY_STREAM")

    File.write!(Path.join(tmp_dir, "my_stream.exs"), """
    defmodule MyStreamConfig do
      import Polyn.StreamConfig

      def configure do
        stream(name: "MY_STREAM", subjects: ["my_subject"])
      end
    end
    """)

    StreamMigrator.run(@conn_name, tmp_dir)

    {:ok, %{config: %{name: "MY_STREAM", subjects: ["my_subject"]}}} =
      Stream.info(@conn_name, "MY_STREAM")
  end

  test "when stream exists already it's a noop", %{tmp_dir: tmp_dir} do
    Stream.delete(@conn_name, "MY_STREAM")
    Stream.create(@conn_name, %Stream{name: "MY_STREAM", subjects: ["my_subject"]})

    File.write!(Path.join(tmp_dir, "my_stream.exs"), """
    defmodule MyStreamConfig do
      import Polyn.StreamConfig

      def configure do
        stream(name: "MY_STREAM", subjects: ["my_subject"])
      end
    end
    """)

    StreamMigrator.run(@conn_name, tmp_dir)

    {:ok, %{config: %{name: "MY_STREAM", subjects: ["my_subject"]}}} =
      Stream.info(@conn_name, "MY_STREAM")
  end

  test "when stream config changes it updates", %{tmp_dir: tmp_dir} do
    Stream.delete(@conn_name, "MY_STREAM")
    Stream.create(@conn_name, %Stream{name: "MY_STREAM", subjects: ["my_subject"]})

    File.write!(Path.join(tmp_dir, "my_stream.exs"), """
    defmodule MyStreamConfig do
      import Polyn.StreamConfig

      def configure do
        stream(name: "MY_STREAM", subjects: ["my_subject"], description: "new interesting facts")
      end
    end
    """)

    StreamMigrator.run(@conn_name, tmp_dir)

    {:ok,
     %{
       config: %{
         name: "MY_STREAM",
         subjects: ["my_subject"],
         description: "new interesting facts"
       }
     }} = Stream.info(@conn_name, "MY_STREAM")
  end
end
