defmodule Polyn.JSONStoreTest do
  use Polyn.ConnCase, async: true

  alias Jetstream.API.KV
  alias Polyn.JSONStore

  @conn_name :json_store_gnat
  @moduletag with_gnat: @conn_name

  @store_name "POLYN_JSON_STORE_TEST"

  setup do
    on_exit(fn ->
      cleanup(fn pid ->
        delete_store(pid)
      end)
    end)
  end

  describe "start_link/1" do
    test "loads content on init" do
      assert :ok = JSONStore.create_store(@conn_name, @store_name)
      KV.put_value(@conn_name, @store_name, "foo", "bar")

      store =
        start_supervised!(
          {JSONStore,
           store_name: @store_name, connection_name: @conn_name, name: String.to_atom(@store_name)}
        )

      assert JSONStore.get_contents(store) == %{"foo" => "bar"}
    end

    @tag capture_log: true
    test "errors after 5 retry attempts" do
      assert :ok = JSONStore.create_store(@conn_name, @store_name)

      %{message: message} =
        assert_raise(RuntimeError, fn ->
          start_supervised!(
            {JSONStore,
             store_name: @store_name,
             connection_name: :bad_connection,
             retry_interval: 1,
             name: String.to_atom(@store_name)}
          )
        end)

      assert message =~ "NATS server :bad_connection not alive"
    end
  end

  describe "create_store/0" do
    test "creates a store" do
      assert :ok = JSONStore.create_store(@conn_name, @store_name)
    end

    test "called multiple times won't break" do
      assert :ok = JSONStore.create_store(@conn_name, @store_name)
      assert :ok = JSONStore.create_store(@conn_name, @store_name)
    end

    test "handles when store already exists with different config" do
      KV.create_bucket(@conn_name, @store_name, description: "foo")
      assert :ok = JSONStore.create_store(@conn_name, @store_name)
    end
  end

  describe "save/2" do
    setup :init_store

    test "persists a new key", %{store: store} do
      assert :ok =
               JSONStore.save(
                 store,
                 "foo.bar",
                 %{type: "null"}
               )

      assert JSONStore.get(store, "foo.bar") == %{"type" => "null"}
    end

    test "updates already existing", %{store: store} do
      assert :ok =
               JSONStore.save(
                 store,
                 "foo.bar",
                 %{type: "string"}
               )

      assert :ok =
               JSONStore.save(
                 store,
                 "foo.bar",
                 %{type: "null"}
               )

      assert JSONStore.get(store, "foo.bar") == %{"type" => "null"}
    end
  end

  describe "delete/1" do
    setup :init_store

    test "deletes a key", %{store: store} do
      assert :ok =
               JSONStore.save(
                 store,
                 "foo.bar",
                 %{
                   type: "null"
                 }
               )

      assert :ok = JSONStore.delete(store, "foo.bar")

      assert JSONStore.get(store, "foo.bar") == nil
    end

    test "deletes a key that doesn't exist", %{store: store} do
      assert :ok = JSONStore.delete(store, "foo.bar")

      assert JSONStore.get(store, "foo.bar") == nil
    end
  end

  describe "get/2" do
    setup :init_store

    test "returns nil if not found", %{store: store} do
      assert JSONStore.get(store, "foo.bar") == nil
    end
  end

  defp init_store(context) do
    JSONStore.create_store(@conn_name, @store_name)

    store =
      start_supervised!(
        {JSONStore,
         store_name: @store_name,
         connection_name: @conn_name,
         contents: %{},
         name: String.to_atom(@store_name)}
      )

    Map.put(context, :store, store)
  end

  defp delete_store(pid) do
    :ok = JSONStore.delete_store(pid, @store_name)
  end
end
