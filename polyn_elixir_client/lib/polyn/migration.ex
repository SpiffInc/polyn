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

  defp runner do
    Process.get(:polyn_migration_runner)
  end
end
