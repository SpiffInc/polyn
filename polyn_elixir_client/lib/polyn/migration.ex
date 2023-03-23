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

  @spec update_stream(stream_options :: keyword()) :: :ok
  def update_stream(opts) when is_list(opts) do
    command = {:update_stream, opts}
    Runner.add_command(runner(), command)
  end

  defp runner do
    Process.get(:polyn_migration_runner)
  end
end
