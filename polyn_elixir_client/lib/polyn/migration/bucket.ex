defmodule Polyn.Migration.Bucket do
  # Functions for working with a JetStream KV bucket for keeping track of
  # which migrations we've already run
  @moduledoc false

  alias Jetstream.API.KV
  alias Polyn.Connection

  @bucket_name "POLYN_MIGRATIONS"
  @no_key_found_code 10_037

  def create(bucket_name \\ @bucket_name) do
    KV.create_bucket(Connection.name(), bucket_name)
  end

  def delete(bucket_name \\ @bucket_name) do
    KV.delete_bucket(Connection.name(), bucket_name)
  end

  def info(bucket_name \\ @bucket_name) do
    Jetstream.API.Stream.info(Connection.name(), "KV_#{bucket_name}")
  end

  def contents(bucket_name \\ @bucket_name) do
    KV.contents(Connection.name(), bucket_name)
  end

  def already_run_migrations(bucket_name \\ @bucket_name) do
    case KV.get_value(Connection.name(), bucket_name, bucket_key()) do
      {:error, %{"err_code" => @no_key_found_code}} ->
        []

      {:error, reason} ->
        raise Polyn.Migration.Exception,
              "Error looking up already run migrations, #{inspect(reason)}"

      nil ->
        []

      migrations ->
        Jason.decode!(migrations)
    end
  end

  def add_migration(migration_id, bucket_name \\ @bucket_name) do
    migrations =
      already_run_migrations(bucket_name)
      |> Enum.concat([migration_id])
      |> Enum.sort()
      |> Jason.encode!()

    KV.put_value(Connection.name(), bucket_name, bucket_key(), migrations)
  end

  def remove_migration(migration_id, bucket_name \\ @bucket_name) do
    migrations =
      already_run_migrations(bucket_name)
      |> Enum.reject(&(&1 == migration_id))
      |> Jason.encode!()

    KV.put_value(Connection.name(), bucket_name, bucket_key(), migrations)
  end

  defp bucket_key do
    # We're using the `source_root` as the namespace/key for all the migrations
    # for the application using Polyn. We're assuming only one application owns the
    # config for any given stream and/or consumers. There should be one bucket for
    # all the applications in the system and each should have its own key with run
    # migrations
    Application.fetch_env!(:polyn, :source_root)
  end
end
