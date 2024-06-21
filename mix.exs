defmodule Books.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "4.2.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      preferred_cli_env: [
        reset: :test
      ],
      releases: [
        books: [
          include_executables_for: [:unix],
          applications: [books_web: :permanent, books_bot: :permanent]
        ]
      ],
      dialyzer: [
        plt_add_apps: [:mix]
      ]
    ]
  end

  defp deps do
    [
      {:distillery, github: "altenwald/distillery"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:ex_check, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, ">= 0.0.0", only: :dev, runtime: false},
      {:sobelow, ">= 0.0.0", only: :dev, runtime: false},
      {:doctor, ">= 0.0.0", only: :dev, runtime: false},
      {:versioce, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      reset: ["cmd --app books mix ecto.reset"],
      "phx.routes": "phx.routes BooksWeb.Router",
      "bump-up": [&bump_up/1, "bump patch"],
      release: [
        &clean_it!/1,
        "local.hex --force",
        "clean",
        "deps.get",
        "compile --force",
        "cmd --app books_web mix npm.install",
        "cmd --app books_web mix assets.deploy",
        release_it!()
      ]
    ]
  end

  defp bump_up(_args) do
    "git diff --name-only --cached origin/$(git branch --show-current)"
    |> get_output!()
    |> String.split("\n")
    |> Enum.map(&(Path.split(&1) |> Enum.slice(0..1) |> Path.join()))
    |> Enum.uniq()
    |> Enum.each(fn app_to_bump_up ->
      IO.puts("bumping up #{app_to_bump_up}")
      Mix.Shell.cmd("mix bump patch", [cd: app_to_bump_up], & &1)
    end)
  end

  defp clean_it!(_args) do
    File.rm_rf("_build/prod/consolidated")
    File.rm_rf("_build/prod/lib")
    File.rm_rf("_build/prod/.mix")
  end

  defp release_it! do
    "git log -1 --format=%s"
    |> get_output!()
    |> then(&Regex.match?(~r/\[no-update\]/, &1))
    |> if do
      "distillery.release --env=prod"
    else
      "distillery.release --upgrade --env=prod"
    end
  end

  defp get_output!(command) do
    command
    |> System.shell()
    |> then(fn {text, 0} -> text end)
    |> String.trim()
  end
end
