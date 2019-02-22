defmodule Exmud.Session.Mixfile do
  use Mix.Project

  def project do
    [
      # Standard arguments
      app: :session,
      deps: deps(),
      elixir: "~> 1.8.1",
      elixirc_paths: elixirc_paths(Mix.env()),
      version: "0.1.0",

      # Build arguments
      build_embedded: Mix.env() == :prod,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",

      # Run arguments
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Exmud.Session.Application, []}
    ]
  end

  defp deps do
    [
      {:calendar, "~> 0.17.4"},
      {:credo, "~> 1.0.2", only: [:dev, :test]},
      {:e_queue, "~> 1.0.1"},
      {:ecto, "~> 3.0.7"},
      {:ex_doc, ">= 0.19.3", only: :dev},
      {:excoveralls, ">= 0.10.5", only: :test},
      {:common, in_umbrella: true},
      {:faker, "~> 0.12.0", only: [:dev, :test]},
      {:inch_ex, ">= 2.0.0", only: :docs},
      {:postgrex, "~> 0.14.1"},
      {:uuid, "~> 1.1.8"}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      test: [
        "ecto.drop --quiet MIX_ENV=test",
        "ecto.create --quiet MIX_ENV=test",
        "ecto.migrate --quiet MIX_ENV=test",
        "test"
      ]
    ]
  end
end
