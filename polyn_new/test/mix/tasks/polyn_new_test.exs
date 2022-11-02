defmodule Mix.Tasks.Polyn.NewTest do
  use ExUnit.Case

  @moduletag :tmp_dir
  import Mix.Polyn

  describe "mix project" do
    test "creates a new mix project", %{tmp_dir: tmp_dir} do
      Mix.Task.rerun("polyn.new", [tmp_dir])

      assert mix_file = Path.join(tmp_dir, "#{default_app_name()}/mix.exs") |> File.read!()
      assert mix_file =~ "app: :polyn_hive"
      assert mix_file =~ "{:polyn_events, \"~> 0.1.0\"}"
      assert mix_file =~ "{:polyn_messages, \"~> 0.1.0\"}"
      assert mix_file =~ "mod: {PolynHive.Application"
    end

    test "does not create a mix project if already in one", %{tmp_dir: tmp_dir} do
      Mix.Task.rerun("new", [Path.join(tmp_dir, "foo")])

      Mix.Task.rerun("polyn.new", [Path.join(tmp_dir, "foo")])

      refute Path.join(tmp_dir, "#{default_app_name()}/mix.exs") |> File.exists?()
    end
  end

  describe "schemas_dir" do
    test "creates a schemas directory", %{tmp_dir: tmp_dir} do
      Mix.Task.rerun("polyn.new", [tmp_dir])

      assert File.dir?(Path.join([tmp_dir, default_app_name(), "message_schemas"]))
    end
  end

  describe "docker_compose" do
    test "copies docker_compose.yml", %{tmp_dir: tmp_dir} do
      Mix.Task.rerun("polyn.new", [tmp_dir])

      assert File.exists?(Path.join([tmp_dir, default_app_name(), "docker-compose.yml"]))
    end
  end

  describe "application file" do
    test "includes commanded application in supervision tree", %{tmp_dir: tmp_dir} do
      Mix.Task.rerun("polyn.new", [tmp_dir])

      assert contents =
               Path.join(
                 tmp_dir,
                 "#{default_app_name()}/lib/#{default_app_name()}/application.ex"
               )
               |> File.read!()

      assert contents =~ "{PolynHive.CommandedApplication}"
      assert contents =~ "Supervisor.start_link(children, opts)"
    end
  end

  describe "commanded_application" do
    test "adds commanded_application to current dir", %{tmp_dir: tmp_dir} do
      Mix.Task.rerun("polyn.new", [tmp_dir])

      assert contents =
               Path.join(
                 tmp_dir,
                 "#{default_app_name()}/lib/#{default_app_name()}/commanded_application.ex"
               )
               |> File.read!()

      assert contents =~ "PolynHive.CommandedApplication"
      assert contents =~ "use Commanded.Application, otp_app: :#{default_app_name()}"
    end

    test "uses different app name", %{tmp_dir: tmp_dir} do
      Mix.Task.rerun("polyn.new", [tmp_dir, "--app", "foo"])

      assert contents =
               Path.join(tmp_dir, "foo/lib/foo/commanded_application.ex")
               |> File.read!()

      assert contents =~ "Foo.CommandedApplication"
      assert contents =~ "use Commanded.Application, otp_app: :foo"
    end
  end

  describe "commanded_application_config" do
    test "creates commanded_application config file if non exists", %{tmp_dir: tmp_dir} do
      Mix.Task.rerun("polyn.new", [tmp_dir])

      assert contents =
               Path.join(tmp_dir, "#{default_app_name()}/config/config.exs")
               |> File.read!()

      assert contents =~ "import Config"
      assert contents =~ "config :polyn_hive, PolynHive.CommandedApplication,"
    end

    test "adds commanded_application config to existing config file", %{tmp_dir: tmp_dir} do
      Mix.Task.rerun("new", [Path.join([tmp_dir, default_app_name()])])

      File.mkdir!(Path.join([tmp_dir, "#{default_app_name()}/config"]))

      File.write(Path.join([tmp_dir, "#{default_app_name()}/config/config.exs"]), """
      import Config

      config :foo, :bar
      """)

      Mix.Task.rerun("polyn.new", [tmp_dir])

      assert contents =
               Path.join(tmp_dir, "#{default_app_name()}/config/config.exs")
               |> File.read!()

      assert contents =~ "import Config"
      assert contents =~ "config :foo, :bar"
      assert contents =~ "config :polyn_hive, PolynHive.CommandedApplication,"
    end
  end

  describe "polyn_messages_config" do
    test "generates polyn_messages config", %{tmp_dir: tmp_dir} do
      Mix.Task.rerun("polyn.new", [tmp_dir])

      assert contents =
               Path.join(tmp_dir, "#{default_app_name()}/config/config.exs")
               |> File.read!()

      assert contents =~ "import Config"
      assert contents =~ "config :polyn_messages, :nats_connection_settings, ["
    end
  end
end
