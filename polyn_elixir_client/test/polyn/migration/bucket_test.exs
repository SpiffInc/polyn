defmodule Polyn.Migration.BucketTest do
  use ExUnit.Case, async: true

  alias Polyn.Migration

  setup do
    Migration.Bucket.delete()
    :ok
  end

  test "namespaces the already run migrations by source_root" do
    Migration.Bucket.create()
    Migration.Bucket.add_migration("1234")

    {:ok, %{"user.backend" => "[\"1234\"]"}} = Migration.Bucket.contents()
  end

  test "raises if adding migration when bucket doesn't exist" do
    assert_raise(Polyn.Migration.Exception, fn ->
      Migration.Bucket.add_migration("1234")
    end)
  end
end
