defmodule PolynEventsTest do
  use ExUnit.Case
  doctest PolynEvents

  test "opens bank acount" do
    assert {:ok, _pid} = PolynEvents.Application.start_link()
    assert {:ok, _pid} = AccountBalanceHandler.start_link()

    assert :ok =
             PolynEvents.Application.dispatch(%OpenBankAccount{
               account_number: "ACC123456",
               initial_balance: 1_000
             })
  end

  test "increments balance" do
    assert {:ok, _pid} = PolynEvents.Application.start_link()
    assert {:ok, _pid} = AccountBalanceHandler.start_link()

    assert :ok =
             PolynEvents.Application.dispatch(%IncrementBalance{
               account_number: "ACC123456",
               amount: 1
             })
  end
end
