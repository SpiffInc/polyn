defmodule PolynEvents.MixProject do
  use Mix.Project

  def project do
    [
      app: :polyn_events,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:commanded, "~> 1.4"},
      {:commanded_extreme_adapter, "~> 1.1"},
      {:jason, "~> 1.4"},
      {:polyn, "~> 0.3"}
    ]
  end
end
