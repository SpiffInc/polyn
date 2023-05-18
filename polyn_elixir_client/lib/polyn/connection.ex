defmodule Polyn.Connection do
  # Utilities to help work with server connection
  @moduledoc false

  @doc """
  The Gnat.Connection supervisor doesn't block on its startup. So
  even if the application has started that doesn't mean the connection
  is established. This function will block for a connection or timeout
  """
  def wait_for_connection do
    task =
      Task.async(fn ->
        check_connection()
      end)

    Task.await(task)
  end

  defp wait_for_connection(result) do
    case result do
      nil -> check_connection()
      _pid -> :ok
    end
  end

  defp check_connection do
    Process.whereis(name()) |> wait_for_connection()
  end

  @doc """
  Get the name of the NATS server connection
  """
  def name do
    config().name
  end

  defp config do
    Application.fetch_env!(:polyn, :nats)
  end
end
