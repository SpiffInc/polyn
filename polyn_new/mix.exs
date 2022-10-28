defmodule PolynNew.MixProject do
  use Mix.Project

  @github "https://github.com/SpiffInc/polyn/tree/main/polyn_new"

  def project do
    [
      app: :polyn_new,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      source_url: @github,
      deps: deps(),
      aliases: aliases(),
      package: [
        maintainers: [
          "Brandyn Bennett"
        ],
        licenses: ["Apache-2.0"],
        links: %{"GitHub" => @github}
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      lint: ["credo --strict"]
    ]
  end
end
