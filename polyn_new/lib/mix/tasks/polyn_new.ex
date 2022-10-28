defmodule Mix.Tasks.Polyn.New do
  @moduledoc """
  Used to generate boilerplate for a Polyn project.

  ```bash
  mix polyn.new [dir] [--app APP]
  ```

  Defaults to current working directory, but you can pass an optional path to generate in

  An `--app` option can be passed to override the default `polyn_hive` name
  """
  @shortdoc "Generates boilerplate for a Polyn project"

  use Mix.Task
  require Mix.Generator
  import Mix.Polyn

  defstruct [:base_dir, :app, :base_module]

  @impl Mix.Task
  def run(args) do
    {parsed, args} = OptionParser.parse!(args, strict: [app: :string])

    app = Keyword.get(parsed, :app, default_app_name())

    args =
      struct!(__MODULE__,
        base_dir: Enum.at(args, 0, File.cwd!()),
        app: app,
        base_module: Macro.camelize(app)
      )

    gen_mix_project(args)
    gen_schemas_dir(args)
    gen_commanded_application(args)
    gen_commanded_application_config(args)
    copy_docker_yml(args)
  end

  defp gen_mix_project(args) do
    if File.exists?(Path.join([args.base_dir, args.app, "mix.exs"])) do
      Mix.shell().info("Mix project already exists, not generating a new one")
    else
      Mix.Task.rerun("new", [Path.join([args.base_dir, args.app]), "--sup"])
      add_dependencies(args)
    end
  end

  defp add_dependencies(args) do
    Mix.Generator.create_file(
      Path.join([args.base_dir, args.app, "mix.exs"]),
      mix_exs_template(
        app: String.to_atom(args.app),
        base_module: args.base_module
      ),
      force: true
    )
  end

  defp gen_schemas_dir(args) do
    Mix.Generator.create_file(
      Path.join([args.base_dir, args.app, "message_schemas/.gitkeep"]),
      ""
    )
  end

  defp gen_commanded_application(args) do
    Mix.Generator.create_file(
      "#{args.base_dir}/#{args.app}/lib/#{args.app}/commanded_application.ex",
      commanded_application_template(
        app: String.to_atom(args.app),
        base_module: args.base_module
      )
    )
  end

  defp gen_commanded_application_config(args) do
    path = Path.join([args.base_dir, "#{args.app}/config/config.exs"])

    content =
      commanded_application_config_template(
        app: String.to_atom(args.app),
        base_module: args.base_module
      )

    unless File.exists?(path) do
      Mix.Generator.create_file(path, """
        # General application configuration
        import Config
      """)
    end

    File.open!(path, [:append], fn file ->
      IO.write(file, "\n" <> content)
    end)
  end

  defp copy_docker_yml(args) do
    Mix.Generator.copy_file(
      Application.app_dir(:polyn_new, "priv/docker-compose.yml"),
      Path.join([args.base_dir, args.app, "docker-compose.yml"])
    )
  end

  Mix.Generator.embed_template(:commanded_application, """
  defmodule <%= @base_module %>.CommandedApplication do
    use Commanded.Application, otp_app: <%= inspect(@app) %>
  end
  """)

  Mix.Generator.embed_template(:commanded_application_config, """
  config <%= inspect(@app) %>, <%= @base_module %>.CommandedApplication,
    # https://hexdocs.pm/commanded_extreme_adapter/getting-started.html#content
    event_store: [
      adapter: Commanded.EventStore.Adapters.Extreme,
      serializer: Commanded.Serialization.JsonSerializer,
      stream_prefix: "polyn_events",
      extreme: [
        db_type: :node,
        host: "localhost",
        port: 1113,
        username: "admin",
        password: "changeit",
        reconnect_delay: 2_000,
        max_attempts: :infinity
      ]
    ],
    pubsub: :local,
    registry: :local,
    snapshotting: %{}
  """)

  Mix.Generator.embed_template(:mix_exs, """
  defmodule <%= @base_module %>.MixProject do
    use Mix.Project

    def project do
      [
        app: <%= inspect(@app) %>,
        version: "0.1.0",
        elixir: "~> <%= System.build_info().version %>",
        start_permanent: Mix.env() == :prod,
        deps: deps()
      ]
    end

    # Run "mix help compile.app" to learn about applications.
    def application do
      [
        extra_applications: [:logger],
        mod: {<%= @base_module %>.Application, []}
      ]
    end

    # Run "mix help deps" to learn about dependencies.
    defp deps do
      [
        {:polyn_events, "~> 0.1.0"},
      ]
    end
  end
  """)
end
