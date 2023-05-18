defmodule Polyn.JSONStore do
  # A process for loading and accessing key value data from the NATS server.
  @moduledoc false

  use GenServer

  alias Jetstream.API.KV

  @already_in_use_code 10_058
  @default_retry_timeout 5_000
  @default_retry_interval 1_000
  @default_retries 5

  @type option ::
          {:connection_name, Gnat.t()}
          | {:store_name, binary()}
          | {:contents, map()}
          | {:retry_interval, pos_integer()}
          | GenServer.option()

  @doc """
  Start a new Store process

  ## Examples

      iex>Polyn.Jetstream.KeyValueStore.start_link(connection_name: :gnat)
      :ok
  """
  @spec start_link(opts :: [option()]) :: GenServer.on_start()
  def start_link(opts) do
    {store_args, server_opts} =
      Keyword.split(opts, [:contents, :store_name, :connection_name, :retry_interval])

    # For applications and application testing there should only be one Store running.
    # For testing the library there could be multiple
    process_name = Keyword.fetch!(store_args, :store_name) |> process_name()
    server_opts = Keyword.put_new(server_opts, :name, process_name)
    GenServer.start_link(__MODULE__, store_args, server_opts)
  end

  # Get a process name for a given store name. We expect there to be one server per
  # store so by making the names the same we don't have to pass a `pid` around as well
  @doc false
  def process_name(store_name) when is_binary(store_name), do: String.to_atom(store_name)
  def process_name(store_name) when is_atom(store_name), do: store_name

  @doc false
  @spec get_contents(pid()) :: map()
  def get_contents(pid) do
    GenServer.call(pid, :get_contents)
  end

  # Persist a value
  @doc false
  @spec save(pid :: pid(), key :: binary(), value :: map()) :: :ok
  def save(pid, key, value) when is_map(value) do
    GenServer.call(pid, {:save, key, encode(value)})
  end

  defp encode(schema) do
    case Jason.encode(schema) do
      {:ok, encoded} -> encoded
      {:error, reason} -> raise Polyn.JSONStoreException, inspect(reason)
    end
  end

  # Remove a key
  @doc false
  @spec delete(pid :: pid(), key :: binary()) :: :ok
  def delete(pid, key) do
    GenServer.call(pid, {:delete, key})
  end

  # Get the value for a key
  @doc false
  @spec get(pid :: pid(), key :: binary()) :: nil | map()
  def get(pid, key) do
    case GenServer.call(pid, {:get, key}) do
      nil ->
        nil

      value ->
        Jason.decode!(value)
    end
  end

  # Create the store if it doesn't exist already.
  @doc false
  @spec create_store(conn :: Gnat.t(), store_name :: binary()) :: :ok
  def create_store(conn, store_name) do
    result = KV.create_bucket(conn, store_name)

    case result do
      {:ok, _info} -> :ok
      # If some other client created the store first, with a slightly different
      # description or config we'll just use the existing one
      {:error, %{"err_code" => @already_in_use_code}} -> :ok
      {:error, reason} -> raise Polyn.JSONStoreException, inspect(reason)
    end
  end

  # Delete the store. Useful for test
  @doc false
  @spec delete_store(conn :: Gnat.t(), store_name :: binary()) :: :ok
  def delete_store(conn, store_name) do
    KV.delete_bucket(conn, store_name)
  end

  @impl GenServer
  def init(init_args) do
    store_name = Keyword.fetch!(init_args, :store_name)
    conn = Keyword.fetch!(init_args, :connection_name)
    preloaded_contents = Keyword.get(init_args, :contents)
    retry_interval = Keyword.get(init_args, :retry_interval, @default_retry_interval)

    contents = preloaded_contents || start_load_contents(conn, store_name, retry_interval)

    {:ok, %{conn: conn, store_name: store_name, contents: contents}}
  end

  # The `Gnat.ConnectionSupervisor` doesn't block for a connection so it's possible for
  # the `KeyValueStore` process to `init` without the connection being established
  defp start_load_contents(conn, store_name, retry_interval, retries_left \\ @default_retries) do
    task =
      Task.async(fn ->
        load_contents(%{
          conn: conn,
          store_name: store_name,
          retries_left: retries_left,
          retry_interval: retry_interval
        })
      end)

    case Task.yield(task, @default_retry_timeout) do
      {:ok, contents} ->
        contents

      nil ->
        contents_load_failed(%{
          conn: conn,
          store_name: store_name,
          failed_reason: "Connection timeout after #{@default_retry_timeout}"
        })
    end
  end

  defp load_contents(%{retries_left: 0} = args) do
    contents_load_failed(args)
  end

  defp load_contents(%{conn: conn} = args) do
    with true <- connection_alive?(conn),
         {:ok, contents} <- KV.contents(conn, args.store_name) do
      contents
    else
      {:error, reason} ->
        args =
          Map.put(args, :failed_reason, reason)
          |> Map.put(:retries_left, args.retries_left - 1)

        :timer.sleep(args.retry_interval)
        load_contents(args)
    end
  end

  defp contents_load_failed(args) do
    raise Polyn.JSONStoreException,
          "Could not connect to Key Value Store #{args.store_name} with connection #{inspect(args.conn)}, #{inspect(args.failed_reason)}"
  end

  defp connection_alive?(conn) when is_pid(conn) do
    Process.alive?(conn)
  end

  defp connection_alive?(conn) do
    case Process.whereis(conn) do
      nil -> {:error, "NATS server #{inspect(conn)} not alive"}
      _pid -> true
    end
  end

  @impl GenServer
  def handle_call(:get_contents, _from, state) do
    {:reply, state.contents, state}
  end

  def handle_call({:save, key, value}, _from, state) do
    contents = Map.put(state.contents, key, value)
    {:reply, :ok, %{state | contents: contents}}
  end

  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state.contents, key), state}
  end

  def handle_call({:delete, key}, _from, state) do
    contents = Map.delete(state.contents, key)
    {:reply, :ok, %{state | contents: contents}}
  end
end
