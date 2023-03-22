defmodule Polyn.StreamManagerTest do
  use Polyn.ConnCase, async: true

  alias Polyn.StreamManager
  alias Jetstream.API.Stream

  @moduletag :tmp_dir
  @conn_name :stream_manager_test
  @moduletag with_gnat: @conn_name

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

    StreamManager.run(@conn_name, tmp_dir)

    {:ok, %{config: %{name: "MY_STREAM", subjects: ["my_subject"]}}} =
      Stream.info(@conn_name, "MY_STREAM")
  end
end
