defmodule Polyn.NamingTest do
  use ExUnit.Case, async: true

  alias Polyn.Naming

  describe "validate_message_name!/1" do
    test "valid names that's alphanumeric and dot separated passes" do
      assert Naming.validate_message_name!("user.created") == :ok
    end

    test "valid names that's alphanumeric and dot separated (3 dots) passes" do
      assert Naming.validate_message_name!("user.created.foo") == :ok
    end

    test "name can't have spaces" do
      assert_raise(Polyn.NamingException, fn ->
        Naming.validate_message_name!("user   created")
      end)
    end

    test "name can't have tabs" do
      assert_raise(Polyn.NamingException, fn ->
        Naming.validate_message_name!("user\tcreated")
      end)
    end

    test "name can't have linebreaks" do
      assert_raise(Polyn.NamingException, fn ->
        Naming.validate_message_name!("user\n\rcreated")
      end)
    end

    test "names can't have special characters" do
      assert_raise(Polyn.NamingException, fn ->
        Naming.validate_message_name!("user:*%[]<>$!@#-_created")
      end)
    end

    test "names can't start with a dot" do
      assert_raise(Polyn.NamingException, fn ->
        Naming.validate_message_name!(".user")
      end)
    end

    test "names can't end with a dot" do
      assert_raise(Polyn.NamingException, fn ->
        Naming.validate_message_name!("user.")
      end)
    end
  end
end
