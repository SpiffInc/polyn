defmodule PolynNaming.MixProject do
  use Mix.Project

  @github "https://github.com/SpiffInc/polyn/tree/main/polyn_naming"

  def project do
    [
      app: :polyn_naming,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      package: [
        description:
          "Utility functions for sharing naming functionality amongst Polyn Elixir libraries",
        maintainers: [
          "Brandyn Bennett"
        ],
        licenses: ["Apache-2.0"],
        links: %{"GitHub" => @github}
      ],
      docs: [
        extras: ["README.md"],
        api_reference: false,
        main: "readme"
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
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false}
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
