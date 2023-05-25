defmodule Polyn.Migration.BucketTest do
  use ExUnit.Case, async: true

  alias Jetstream.API.KV
  alias Polyn.Migration

  @bucket_name "BUCKET_TEST"

  setup do
    Migration.Bucket.delete(@bucket_name)
    :ok
  end

  test "namespaces the already run migrations by source_root" do
    Migration.Bucket.create(@bucket_name)
    Migration.Bucket.add_migration("1234", @bucket_name)

    {:ok, %{"user.backend" => "[\"1234\"]"}} = Migration.Bucket.contents(@bucket_name)
  end

  test "already_run_migrations returns empty list if key deleted" do
    Migration.Bucket.create(@bucket_name)
    Migration.Bucket.add_migration("1234", @bucket_name)

    assert :ok =
             KV.purge_key(
               Polyn.Connection.name(),
               @bucket_name,
               Application.get_env(:polyn, :source_root)
             )

    # wait for purge/delete to complete. The delete is async right now.
    # Can remove this once it is fixed in Jetstream lib
    :timer.sleep(500)

    assert [] = Migration.Bucket.already_run_migrations(@bucket_name)
  end

  test "raises if adding migration when bucket doesn't exist" do
    assert_raise(Polyn.Migration.Exception, fn ->
      Migration.Bucket.add_migration("1234", @bucket_name)
    end)
  end
end
