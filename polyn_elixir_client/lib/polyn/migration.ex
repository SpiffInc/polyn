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
    command = {:create_stream, opts}
    Runner.add_command(runner(), command)
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
    command = {:update_stream, opts}
    Runner.add_command(runner(), command)
  end

  @doc """
  Deletes a Stream for storing messages.

  ## Examples

      iex>delete_stream("test_stream")
      :ok
  """
  @spec delete_stream(stream_name :: binary()) :: :ok
  def delete_stream(stream_name) do
    command = {:delete_stream, stream_name}
    Runner.add_command(runner(), command)
  end

  defp runner do
    Process.get(:polyn_migration_runner)
  end
end
