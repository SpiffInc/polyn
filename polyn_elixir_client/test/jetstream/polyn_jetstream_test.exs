defmodule Polyn.JetstreamTest do
  use Polyn.ConnCase, async: true

  @conn_name :polyn_jetstream_test
  @moduletag with_gnat: @conn_name

  describe "lookup_stream_name!/2" do
    test "finds stream name" do
      stream = %Jetstream.API.Stream{name: "FOO", subjects: ["foo.>"]}
      {:ok, _info} = Jetstream.API.Stream.create(@conn_name, stream)

      assert "FOO" = Polyn.Jetstream.lookup_stream_name!(@conn_name, "foo.bar")

      Jetstream.API.Stream.delete(@conn_name, "FOO")
    end

    test "raises if stream doesn't exist for event" do
      stream = %Jetstream.API.Stream{name: "FOO", subjects: ["foo.>"]}
      {:ok, _info} = Jetstream.API.Stream.create(@conn_name, stream)

      assert_raise(Polyn.StreamException, fn ->
        Polyn.Jetstream.lookup_stream_name!(@conn_name, "other.subject")
      end)

      Jetstream.API.Stream.delete(@conn_name, "FOO")
    end
  end
end
