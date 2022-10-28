defmodule PolynExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :polyn_example,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {PolynExample.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:polyn_events, path: "../polyn_events"}
    ]
  end
end
