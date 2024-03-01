# SPDX-FileCopyrightText: 2023 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Solvent.MixProject do
  use Mix.Project

  def project do
    [
      app: :solvent,
      description: "A fast, in-memory event bus",
      version: "0.3.0",
      elixir: "~> 1.11",
      source_url: "https://github.com/Cantido/solvent",
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "Solvent",
        extras: ["guides/getting-started.livemd"]
      ]
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
      {:benchfella, "~> 0.3.0", only: :dev},
      {:cloudevents, "~> 0.6.1"},
      {:credo, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, ">= 0.0.0", only: :dev, runtime: false},
      {:doctor, ">= 0.0.0", only: :dev, runtime: false},
      {:ex_check, "~> 0.16.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:jason, "~> 1.3"},
      {:mix_audit, ">= 0.0.0", only: [:dev], runtime: false},
      {:telemetry, "~> 0.4 or ~> 1.0"},
      {:telemetry_registry, "~> 0.2 or ~> 0.3"},
      {:uniq, "~> 0.4"}
    ]
  end
end
