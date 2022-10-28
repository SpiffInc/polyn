defmodule UserTest do
  use ExUnit.Case

  describe "CreateUser" do
    test "saves in event store" do
      assert {:ok, _pid} = PolynEvents.Application.start_link()

      assert :ok =
               PolynEvents.Application.dispatch(%CreateUser{
                 id: 1,
                 name: "Toph",
                 email: "toph@earthbenders.com"
               })
    end

    test "publishes nats message" do
    end
  end
end
