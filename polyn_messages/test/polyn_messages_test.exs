defmodule PolynMessagesTest do
  use ExUnit.Case
  doctest PolynMessages

  test "greets the world" do
    assert PolynMessages.hello() == :world
  end
end
