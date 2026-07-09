defmodule CleanerCrm.MixProject do
  use Mix.Project

  def project do
    [
      app: :cleaner_crm,
      version: "0.1.0",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: compilers(Mix.env()),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {CleanerCrmWeb.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test, spex: :test]
    ]
  end

  defp compilers(:test),
    do: [:diagnostics, :boundary, :phoenix_live_view, :erlang, :elixir, :spex, :app]

  # :diagnostics comes from code_my_spec_generators (a dev-only dep), so
  # prod builds (Docker release) must not list it.
  defp compilers(:prod), do: [:boundary, :phoenix_live_view, :erlang, :elixir, :app]

  defp compilers(_),
    do: [:diagnostics, :boundary, :phoenix_live_view, :erlang, :elixir, :app]

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.8.8"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.2.0"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.16"},
      {:req, "~> 0.5"},
      {:oban, "~> 2.18"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},
      {:assent, "~> 0.3"},
      {:cloak_ecto, "~> 1.3"},
      {:cloak, "~> 1.1"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:client_utils, "~> 0.1"},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:sexy_spex, github: "JediLuke/spex", branch: "main", only: :test},
      # SSM-bootstrap secret loading (CleanerCrm.Secrets) — see the
      # devops repo's SSM pattern. Uses the app's existing Req as the
      # ExAws HTTP client (hackney 4.x is already in the tree via
      # httpoison and conflicts with ExAws's default).
      {:ex_aws, "~> 2.5"},
      {:ex_aws_ssm, "~> 2.1"},
      {:boundary, "~> 0.10", runtime: false},
      {:code_my_spec_generators, "~> 0.1", only: :dev},
      {:wallaby, "~> 0.30", only: :test}
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
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["compile", "tailwind cleaner_crm", "esbuild cleaner_crm"],
      "assets.deploy": [
        "tailwind cleaner_crm --minify",
        "esbuild cleaner_crm --minify",
        "phx.digest"
      ],
      precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
    ]
  end
end
