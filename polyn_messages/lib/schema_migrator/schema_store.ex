defmodule Polyn.SchemaMigrator.SchemaStore do
  # Functions for working with Key Value schema store
  @moduledoc false

  alias Jetstream.API.KV
  alias Polyn.SchemaMigrator
  alias Polyn.SchemaMigrator.Stream

  @default_store_name "POLYN_SCHEMAS"

  def create_store(%SchemaMigrator{conn: conn, store_name: store_name} = migrator) do
    unless exists?(migrator) do
      migrator.log.("Schema Store #{store_name} does not exist. Creating it now.")
      replicas = cluster_size(conn) |> num_replicas()
      KV.create_bucket(conn, store_name, replicas: replicas)
    end
  end

  defp exists?(%SchemaMigrator{conn: conn, store_name: store_name}) do
    Stream.exists?(conn, "KV_#{store_name}")
  end

  defp num_replicas(cluster_size) when cluster_size >= 3, do: 3
  defp num_replicas(cluster_size), do: cluster_size

  defp cluster_size(conn) do
    case Gnat.server_info(conn) do
      %{connect_urls: urls} ->
        Enum.count(urls)

      _no_connect_urls ->
        1
    end
  end

  @doc """
  Get the keys and schemas out of the store
  """
  def contents(%SchemaMigrator{conn: conn, store_name: store_name}) do
    KV.contents(conn, store_name)
  end

  @doc """
  Put a schema name and json in the store
  """
  def put(name, schema, %SchemaMigrator{} = migrator) do
    migrator.log.("Saving schema #{name} in the registry")
    KV.put_value(migrator.conn, migrator.store_name, name, Jason.encode!(schema))
  end

  @doc """
  Get the store_name from options or the default
  """
  def get_store_name(opts \\ []) do
    opts[:store_name] || @default_store_name
  end
end
