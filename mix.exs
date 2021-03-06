defmodule Ports.MixProject do
  use Mix.Project

  @source_url "https://github.com/martide/ports"
  @version "0.1.1"

  def project do
    [
      app: :ports,
      version: @version,
      elixir: "~> 1.10",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: @source_url,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:nimble_csv, "~> 1.1"},
      {:dialyxir, "~> 1.1", only: ~w(dev test)a, runtime: false},
      {:ex_doc, "~> 0.27", only: :dev},
      {:excoveralls, "~> 0.14", only: :test}
    ]
  end

  defp description do
    """
      Ports is a collection of United Nations Code for Trade and Transport Locations or known as "UN/LOCODE".
    """
  end

  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        "README*",
        "CHANGELOG*",
        "LICENSE*",
        "priv/data/code-list.csv",
        "priv/data/country-codes.csv",
        "priv/data/function-classifiers.csv",
        "priv/data/status-indicators.csv",
        "priv/data/subdivision-codes.csv"
      ],
      maintainers: ["Martide"],
      licenses: ["Apache-2.0"],
      links: %{"Github" => @source_url}
    ]
  end
end
