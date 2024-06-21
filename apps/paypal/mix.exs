defmodule Paypal.MixProject do
  use Mix.Project

  def project do
    [
      app: :paypal,
      version: "0.1.1",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Paypal.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.4"},
      {:gen_state_machine, "~> 3.0"},
      {:jason, "~> 1.3"},

      # internal quality
      {:doctor, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
