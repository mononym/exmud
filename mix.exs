defmodule ExmudUmbrella.Mixfile do
  use Mix.Project

  def project do
    [
      aliases: aliases(),
      apps_path: "apps",
      build_embedded: Mix.env == :prod,
      deps: deps(),
      preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
      start_permanent: Mix.env == :prod,
      test_coverage: [tool: ExCoveralls]
    ]
  end

  defp deps do
    [
      {:calendar, "~> 0.17.2"},
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:ex_doc, ">= 0.14.5", only: :dev},
      {:excoveralls, ">= 0.7.0", only: :test},
      {:inch_ex, ">= 0.5.6", only: :docs}
    ]
  end

  defp aliases do
    ["test": ["ecto.drop --quiet -r Exmud.DB.Repo MIX_ENV=test",
              "ecto.create --quiet -r Exmud.DB.Repo MIX_ENV=test",
              "ecto.migrate -r Exmud.DB.Repo MIX_ENV=test",
              "test"]]
  end
end
