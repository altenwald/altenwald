defmodule Books.MixProject do
  use Mix.Project

  def project do
    [
      app: :books,
      version: "4.2.2",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [
        "ecto.reset": :test
      ],
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Books.Application, []},
      extra_applications: [:logger, :runtime_tools]
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
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:ecto_sql, "~> 3.6"},
      {:scrivener_ecto, "~> 2.7"},
      {:scrivener_list, "~> 2.0"},
      {:familiar, "~> 0.1"},
      {:typed_ecto_schema, "~> 0.4"},
      {:postgrex, ">= 0.0.0"},
      {:jason, "~> 1.2"},
      {:swoosh, "~> 1.3"},
      {:plug, "~> 1.14"},
      {:multipart, "~> 0.4"},
      {:tesla, "~> 1.4"},
      {:money, "~> 1.8"},
      {:hashids, "~> 2.0"},
      {:countries, "~> 1.6"},
      {:cronex, github: "altenwald/cronex"},
      {:sitemap, github: "manuel-rubio/sitemap"},
      {:gen_state_machine, "~> 3.0"},
      {:timex, "~> 3.6"},
      {:hackney, "~> 1.18"},
      {:geoip, in_umbrella: true},
      {:mailchimp, in_umbrella: true},
      {:paypal, in_umbrella: true},
      {:stripe, in_umbrella: true},

      # observability
      {:recon, "~> 2.5", only: :prod},
      {:observer_cli, "~> 1.7", only: :prod},

      # for releases
      {:ecto_boot_migration, "~> 0.2"},
      {:versioce, ">= 0.0.0", only: :dev, runtime: false},

      # internal quality
      {:doctor, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"]
    ]
  end
end
