defmodule BooksBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :books_bot,
      version: "0.1.2",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {BooksBot.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_pubsub, "~> 2.0"},
      {:ex_gram, "~> 0.50"},
      {:tesla, "~> 1.8"},
      {:finch, "~> 0.17"},
      {:jason, "~> 1.4"},
      {:gen_state_machine, "~> 3.0"},
      {:books, in_umbrella: true},
      {:doctor, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
