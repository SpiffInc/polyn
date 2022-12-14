defmodule Polyn.NamingTest do
  use ExUnit.Case, async: true

  alias Polyn.Naming

  test "dot_to_colon/1" do
    assert "com:acme:user:created:v1:schema:v1" ==
             Naming.dot_to_colon("com.acme.user.created.v1.schema.v1")
  end

  test "colon_to_dot/1" do
    assert "com.acme.user.created.v1.schema.v1" ==
             Naming.colon_to_dot("com:acme:user:created:v1:schema:v1")
  end

  describe "trim_domain_prefix/1" do
    test "removes prefix when dots" do
      assert "user.created.v1.schema.v1" ==
               Naming.trim_domain_prefix("com.test.user.created.v1.schema.v1")
    end

    test "removes prefix when colon" do
      assert "user:created:v1:schema:v1" ==
               Naming.trim_domain_prefix("com:test:user:created:v1:schema:v1")
    end

    test "only removes first occurence" do
      assert "user.created.com.test.v1.schema.v1" ==
               Naming.trim_domain_prefix("com.test.user.created.com.test.v1.schema.v1")
    end
  end

  test "version_suffix/1 defaults to version 1" do
    assert Naming.version_suffix("com:acme:user:created:") ==
             "com:acme:user:created:v1"
  end

  test "version_suffix/2 adds version" do
    assert Naming.version_suffix("com:acme:user:created:", 2) ==
             "com:acme:user:created:v2"
  end

  describe "trim_version_suffix/1" do
    test "with dots" do
      assert Naming.trim_version_suffix("com.acme.user.created.v1") == "com.acme.user.created"
    end

    test "with colons" do
      assert Naming.trim_version_suffix("com:acme:user:created:v1") == "com:acme:user:created"
    end
  end

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

  describe "validate_source_name!/1" do
    test "valid name that's alphanumeric and dot separated passes" do
      assert Naming.validate_source_name!("user.backend") == :ok
    end

    test "valid name that's alphanumeric and dot separated (3 dots) passes" do
      assert Naming.validate_source_name!("nats.graphql.proxy") == :ok
    end

    test "valid name that's alphanumeric and colon separated passes" do
      assert Naming.validate_source_name!("user:backend") == :ok
    end

    test "source can't have spaces" do
      assert_raise(Polyn.NamingException, fn ->
        Naming.validate_source_name!("user   created")
      end)
    end

    test "source can't have tabs" do
      assert_raise(Polyn.NamingException, fn ->
        Naming.validate_source_name!("user\tcreated")
      end)
    end

    test "source can't have linebreaks" do
      assert_raise(Polyn.NamingException, fn ->
        Naming.validate_source_name!("user\n\rcreated")
      end)
    end

    test "source can't have special characters" do
      assert_raise(Polyn.NamingException, fn ->
        Naming.validate_source_name!("user:*%[]<>$!@#-_created")
      end)
    end

    test "source can't start with a dot" do
      assert_raise(Polyn.NamingException, fn ->
        Naming.validate_source_name!(".user")
      end)
    end

    test "source can't end with a dot" do
      assert_raise(Polyn.NamingException, fn ->
        Naming.validate_source_name!("user.")
      end)
    end

    test "source can't start with a colon" do
      assert_raise(Polyn.NamingException, fn ->
        Naming.validate_source_name!(":user")
      end)
    end

    test "source can't end with a colon" do
      assert_raise(Polyn.NamingException, fn ->
        Naming.validate_source_name!("user:")
      end)
    end
  end

  describe "consumer_name/2" do
    test "raises if event type is invalid" do
      assert_raise(Polyn.NamingException, fn ->
        Naming.consumer_name("foo bar")
      end)
    end

    test "raises if optional source is invalid" do
      assert_raise(Polyn.NamingException, fn ->
        Naming.consumer_name("foo.bar", "my source")
      end)
    end

    test "uses source_root by default" do
      assert Naming.consumer_name("foo.bar.v1") == "user_backend_foo_bar_v1"
    end

    test "takes optional source" do
      assert Naming.consumer_name("foo.bar.v1", "my.source") ==
               "user_backend_my_source_foo_bar_v1"
    end

    test "takes colon separated source" do
      assert Naming.consumer_name("foo.bar.v1", "my:source") ==
               "user_backend_my_source_foo_bar_v1"
    end

    test "takes domain prefixed type" do
      assert Naming.consumer_name("com.test.foo.bar.v1", "my:source") ==
               "user_backend_my_source_foo_bar_v1"
    end
  end

  describe "subject_matches?/2" do
    test "equal one token" do
      assert Naming.subject_matches?("foo", "foo") == true
    end

    test "equal 3 tokens" do
      assert Naming.subject_matches?("foo.bar.v1", "foo.bar.v1") == true
    end

    test "not equal 3 token" do
      assert Naming.subject_matches?("foo.bar.v1", "bar.baz.v1") == false
    end

    test "equal with 1 wildcard" do
      assert Naming.subject_matches?("foo.bar", "foo.*") == true
    end

    test "not equal with 1 wildcard" do
      assert Naming.subject_matches?("foo", "foo.*") == false
    end

    test "equal with 2 wildcards" do
      assert Naming.subject_matches?("foo.bar.baz", "foo.*.*") == true
    end

    test "not equal with 2 wildcards" do
      assert Naming.subject_matches?("foo.bar", "foo.*.*") == false
    end

    test "equal with 1 multiple-wildcard" do
      assert Naming.subject_matches?("foo.bar", "foo.>") == true
    end

    test "equal with 1 multiple-wildcard, multiple tokens" do
      assert Naming.subject_matches?("foo.bar.baz.qux", "foo.>") == true
    end

    test "not equal with 1 multiple-wildcard, multiple tokens" do
      assert Naming.subject_matches?("foo", "foo.bar.>") == false
    end

    test "equal with 1 single-wildcard and 1 multiple-wildcard, multiple tokens" do
      assert Naming.subject_matches?("foo.bar.baz.qux", "foo.*.>") == true
    end

    test "equal with 2 single-wildcard and 1 multiple-wildcard, multiple tokens" do
      assert Naming.subject_matches?(
               "foo.bar.baz.qux.other.thing",
               "foo.*.*.>"
             ) == true
    end

    test "not equal with 2 single-wildcard and 1 multiple-wildcard, multiple tokens" do
      assert Naming.subject_matches?("foo.bar", "foo.*.*.>") == false
    end
  end

  describe "stream_name/1" do
    test "upcase and underscore message name" do
      assert Naming.stream_name("foo.bar") == "FOO_BAR"
    end
  end
end
