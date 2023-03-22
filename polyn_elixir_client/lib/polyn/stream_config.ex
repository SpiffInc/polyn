defmodule Polyn.StreamConfig do
  @moduledoc """
  Functions for declaring configuration for a stream and/or consumers
  """

  @doc """
  Declare the configuration for a stream. `fields` are allowable Stream fields as
  defined on `Jetstream.API.Stream.t()`

  ## Examples

      iex>Polyn.StreamConfig.stream(name: "MY_STREAM", subjects: ["my_subject"])
      {:stream, fields}
      iex>Polyn.StreamConfig.stream(%{name: "MY_STREAM", subjects: ["my_subject"]})
      {:stream, fields}
  """
  def stream(fields) do
    {:stream, fields}
  end

  @doc """
  Declare the configuration for a consumer. `fields` are allowable Consumer fields as
  defined on `Jetstream.API.Consumer.t()`

  ## Examples

      iex>Polyn.StreamConfig.consumer(stream_name: "MY_STREAM", durable_name: ["my_consumer"])
      {:consumer, fields}
      iex>Polyn.StreamConfig.consumer(%{stream_name: "MY_STREAM", durable_name: ["my_consumer"]})
      {:consumer, fields}
  """
  def consumer(fields) do
    {:consumer, fields}
  end
end
