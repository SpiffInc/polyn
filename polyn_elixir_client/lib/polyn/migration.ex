defmodule Polyn.Migration do
  @moduledoc """
  Functions for making changes to a NATS server
  """

  alias Polyn.Migration.Runner

  @doc """
  Creates a new Stream for storing messages. Options are what's available on
  `Jetstream.API.Stream.t()`

  ## Examples

      iex>create_stream(name: "test_stream", subjects: ["test_subject"])
      :ok
  """
  @spec create_stream(stream_options :: keyword()) :: :ok
  def create_stream(opts) when is_list(opts) do
    Runner.add_command(runner(), :create_stream, opts)
  end

  @doc """
  Updates a Stream for storing messages. Options are what's available on
  `Jetstream.API.Stream.t()`. The `:name` is required and must be an already
  created Stream

  ## Examples

      iex>update_stream(name: "test_stream", description: "my test stream")
      :ok
  """
  @spec update_stream(stream_options :: keyword()) :: :ok
  def update_stream(opts) when is_list(opts) do
    Runner.add_command(runner(), :update_stream, opts)
  end

  @doc """
  Deletes a Stream for storing messages.

  ## Examples

      iex>delete_stream("test_stream")
      :ok
  """
  @spec delete_stream(stream_name :: binary()) :: :ok
  def delete_stream(stream_name) do
    Runner.add_command(runner(), :delete_stream, stream_name)
  end

  @doc """
  Creates a new Consumer for a stream. Options are what's available on
  `Jetstream.API.Consumer.t()`.
  Note: Consumers can't be updated after they are created. You must delete and
  recreate it instead.

  ## Examples

      iex>create_consumer(durable_name: "test_consumer", stream_name: "test_stream")
      :ok
  """
  @spec create_consumer(consumer_options :: keyword()) :: :ok
  def create_consumer(opts) when is_list(opts) do
    Runner.add_command(runner(), :create_consumer, opts)
  end

  @doc """
  Deletes a consumer from a stream. Consumers can have the same name for different
  streams so you must supply the stream name.

  ## Examples

      iex>delete_consumer(durable_name: "test_consumer", stream_name: "test_stream")
      :ok
  """
  @spec delete_consumer(consumer_options :: keyword()) :: :ok
  def delete_consumer(opts) when is_list(opts) do
    Runner.add_command(runner(), :delete_consumer, opts)
  end

  defp runner do
    Process.get(:polyn_migration_runner)
  end
end
