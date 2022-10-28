defmodule PolynHive.MixProject do
  use Mix.Project

  def project do
    [
      app: :polyn_hive,
      version: "0.1.0",
      elixir: "~> 1.14.0",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {PolynHive.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:polyn_events, "~> 0.1.0"},
    ]
  end
end
