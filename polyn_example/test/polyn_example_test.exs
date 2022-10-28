defmodule PolynExampleTest do
  use ExUnit.Case
  doctest PolynExample

  test "greets the world" do
    assert PolynExample.hello() == :world
  end
end
