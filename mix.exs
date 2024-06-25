defmodule Ports.MixProject do
  use Mix.Project

  @source_url "https://github.com/martide/ports"
  @version "0.1.2"

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
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.json": :test,
        "coveralls.post": :test
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:nimble_csv, "~> 1.1"},
      {:ex_doc, "~> 0.27", only: :dev},
      {:excoveralls, "~> 0.14", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.11", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
      Ports is a collection of United Nations Code for Trade and Transport Locations or known as "UN/LOCODE".
    """
  end

  defp package do
    [
      maintainers: ["Martide"],
      licenses: ["Apache-2.0"],
      links: %{"Github" => @source_url}
    ]
  end
end
