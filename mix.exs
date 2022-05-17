defmodule Solvent.MixProject do
  use Mix.Project

  def project do
    [
      app: :solvent,
      description: "A fast, in-memory event bus",
      version: "0.2.0",
      elixir: "~> 1.13",
      source_url: "https://github.com/Cantido/solvent",
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Solvent.Application, []}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/Cantido/solvent",
        "Sponsor" => "https://liberapay.org/rosa"
      }
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:elixir_uuid, "~> 1.2"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:telemetry, "~> 1.0"}
    ]
  end
end
