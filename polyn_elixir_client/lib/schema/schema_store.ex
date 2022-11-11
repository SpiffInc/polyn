defmodule Polyn.SchemaStore do
  @moduledoc """
  A SchemaStore for loading and accessing schemas from the NATS server that were
  created via Polyn CLI.

  You will need this running, likely in your application supervision tree, in order for
  Polyn to access schemas

  ## Examples

      ```elixir
      children = [
        {Polyn.SchemaStore, connection_name: :connection_name_or_pid}
      ]

      opts = [strategy: :one_for_one, name: MySupervisor]
      Supervisor.start_link(children, opts)
      ```
  """

  alias Polyn.JSONStore

  @store_name "POLYN_SCHEMAS"

  @type option :: JSONStore.option() | {:schemas, map()}

  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}
  end

  @doc """
  Start a new SchemaStore process

  ## Examples

      iex>Polyn.SchemaStore.start_link(connection_name: :gnat)
      :ok
  """
  @spec start_link(opts :: [option]) :: GenServer.on_start()
  def start_link(opts) do
    opts =
      Keyword.put_new(opts, :store_name, @store_name)
      |> Keyword.put(:contents, opts[:schemas])

    JSONStore.start_link(opts)
  end

  @doc false
  @spec get_schemas(pid()) :: map()
  def get_schemas(pid) do
    JSONStore.get_contents(pid)
  end

  # Persist a schema. In prod/dev schemas should have already been persisted via
  # the Polyn CLI.
  @doc false
  @spec save(pid :: pid(), name :: binary(), schema :: map()) :: :ok
  def save(pid, name, schema) when is_map(schema) do
    is_json_schema?(schema)
    JSONStore.save(pid, name, schema)
  end

  defp is_json_schema?(schema) do
    ExJsonSchema.Schema.resolve(schema)
  rescue
    ExJsonSchema.Schema.InvalidSchemaError ->
      reraise Polyn.SchemaException,
              [message: "Schemas must be valid JSONSchema documents, got #{inspect(schema)}"],
              __STACKTRACE__
  end

  # Remove a schema
  @doc false
  @spec delete(pid :: pid(), name :: binary()) :: :ok
  defdelegate delete(pid, name), to: JSONStore

  # Get the schema for a message
  @doc false
  @spec get(pid :: pid(), name :: binary()) :: nil | map()
  defdelegate get(pid, name), to: JSONStore

  # Create the schema store if it doesn't exist already. In prod/dev the the store
  # creation should have already been done via the Polyn CLI
  @doc false
  @spec create_store(conn :: Gnat.t()) :: :ok
  @spec create_store(conn :: Gnat.t(), opts :: keyword()) :: :ok
  def create_store(conn, opts \\ []) do
    JSONStore.create_store(conn, store_name(opts))
  end

  # Delete the schema store. Useful for test
  @doc false
  @spec delete_store(conn :: Gnat.t()) :: :ok
  @spec delete_store(conn :: Gnat.t(), opts :: keyword()) :: :ok
  def delete_store(conn, opts \\ []) do
    JSONStore.delete_store(conn, store_name(opts))
  end

  @doc """
  Get a configured store name or the default
  """
  @spec store_name(opts :: [{:name, binary()}]) :: binary()
  def store_name(opts \\ []) do
    Keyword.get(opts, :name, @store_name)
  end

  defdelegate process_name(store_name), to: JSONStore
end
