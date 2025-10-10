defmodule Meteo.MixProject do
  use Mix.Project

  def project do
    [
      app: :meteo,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Meteo.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.15.3"},
      {:jason, "~> 1.4"},
      {:hackney, "~> 1.13"}
    ]
  end
end
