defmodule BooksWeb.MixProject do
  use Mix.Project

  def project do
    [
      app: :books_web,
      version: "4.2.6",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {BooksWeb.Application, []},
      extra_applications: [:logger, :runtime_tools, :sasl]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.18.3"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.7.2"},
      {:esbuild, "~> 0.3", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.18"},
      {:books, in_umbrella: true},
      {:books_admin, in_umbrella: true},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:phoenix_markdown, "~> 1.0"},
      {:countries_i18n, "~> 0.0"},
      {:remote_ip, "~> 1.0"},
      {:html_sanitize_ex, "~> 1.4"},
      {:hackney, "~> 1.18"},
      {:browser, "~> 0.4"},
      {:cronex, github: "altenwald/cronex"},
      {:earmark, "~> 1.4"},
      {:earmark_parser, "~> 1.4"},
      {:mime, "~> 2.0"},

      # internal quality
      {:sobelow, ">= 0.0.0", only: :dev, runtime: false},
      {:doctor, ">= 0.0.0", only: :dev, runtime: false},
      {:versioce, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "npm.install": [
        "cmd npm --prefix assets install"
      ],
      "assets.deploy": [
        "cmd npm --prefix assets run deploy",
        "phx.digest"
      ],
      setup: ["deps.get", "npm.install"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
