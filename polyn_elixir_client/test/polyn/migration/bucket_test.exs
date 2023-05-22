defmodule Polyn.Migration.BucketTest do
  use ExUnit.Case, async: true

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

  test "raises if adding migration when bucket doesn't exist" do
    assert_raise(Polyn.Migration.Exception, fn ->
      Migration.Bucket.add_migration("1234", @bucket_name)
    end)
  end
end
