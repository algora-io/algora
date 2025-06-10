defmodule Algora.MixProject do
  use Mix.Project

  def project do
    [
      app: :algora,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: [
        plt_local_path: "priv/plts/project.plt",
        plt_core_path: "priv/plts/core.plt",
        ignore_warnings: ".dialyzer_ignore.exs"
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Algora.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:tidewave, "~> 0.1", only: :dev},
      {:phoenix, "~> 1.7.21"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_html, "~> 4.2.1"},
      {:phoenix_live_reload, "~> 1.6", only: :dev},
      {:phoenix_live_view, "~> 1.0.10"},
      {:phoenix_live_dashboard, "~> 0.8.7"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:floki, ">= 0.30.0"},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:tabler_icons, github: "algora-io/icons", sparse: "icons", app: false, compile: false, depth: 1},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:httpoison, "~> 2.2"},
      {:redirect, "~> 0.4.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:plug_cowboy, "~> 2.7"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:joken, "~> 2.5"},
      {:nanoid, "~> 2.1.0"},
      {:ex_cldr, "~> 2.0"},
      {:ex_money, "~> 5.12"},
      {:ex_money_sql, "~> 1.0"},
      {:salad_ui, "~> 0.14.0"},
      {:tails, "~> 0.1.5"},
      {:number, "~> 1.0.1"},
      {:tzdata, "~> 1.1"},
      {:stripity_stripe, "~> 2.17.3"},
      {:live_svelte, "~> 0.14.1"},
      {:nimble_parsec, "~> 1.4"},
      {:nimble_totp, "~> 1.0"},
      {:oban, "~> 2.19"},
      {:oban_web, "~> 2.11"},
      {:styler, "~> 1.2", only: [:dev, :test], runtime: false},
      {:typed_ecto_schema, "~> 0.4.1", runtime: false},
      {:chameleon, "~> 2.2.0"},
      {:ex_machina, "~> 2.8.0", only: [:dev, :test]},
      {:excoveralls, "~> 0.18", only: :test},
      {:dataloader, "~> 2.0.0"},
      {:mdex, "~> 0.2"},
      {:reverse_proxy_plug, "~> 3.0"},
      {:cors_plug, "~> 2.0"},
      {:timex, "~> 3.7"},
      {:yaml_elixir, "~> 2.9"},
      {:hammer, "~> 7.0"},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:cmark, "~> 0.10"},
      {:csv, "~> 3.2"},
      {:instructor, "~> 0.1.0"},
      {:hound, "~> 1.1", only: [:dev]},
      # ex_aws
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, "~> 1.9"},
      # monitoring, logging
      {:appsignal_phoenix, "~> 2.7"},
      {:logfmt_ex, "~> 0.4"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      compile: ["domain_blacklist"],
      "ecto.setup": [
        "ecto.create",
        "ecto.migrate",
        "ecto.seed"
      ],
      "ecto.seed": ["run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "test.reset": ["cmd MIX_ENV=test mix do ecto.drop, ecto.create, ecto.migrate"],
      "assets.setup": ["tailwind.install --if-missing"],
      "assets.build": ["cmd --cd assets pnpm install", "tailwind algora"],
      "assets.deploy": [
        "tailwind algora --minify",
        "cmd --cd assets node build.js --deploy",
        "phx.digest"
      ]
    ]
  end
end
