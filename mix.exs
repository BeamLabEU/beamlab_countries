defmodule BeamLabCountries.MixProject do
  use Mix.Project

  @source_url "https://github.com/BeamLabEU/beamlab_countries"
  @version "2.0.0"

  def project do
    [
      app: :beamlab_countries,
      version: @version,
      elixir: "~> 1.18",
      deps: deps(),
      docs: docs(),
      package: package(),
      aliases: aliases(),
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:ex_unit, :yaml_elixir, :yamerl]
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:yaml_elixir, "~> 2.12", runtime: false},
      {:ex_doc, "~> 0.39", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "README.md": [title: "Overview"],
        "CHANGELOG.md": [title: "Changelog"],
        "LICENSE.md": [title: "License"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: @version,
      formatters: ["html"]
    ]
  end

  defp aliases do
    [
      quality: ["format", "credo --strict", "dialyzer"],
      "quality.ci": ["format --check-formatted", "credo --strict", "dialyzer"],
      precommit: [
        "compile --force --warnings-as-errors",
        "deps.unlock --check-unused",
        # Scan for retired Hex deps. Run via `cmd` so Hex bootstraps in a fresh
        # process — the hex.* archive tasks aren't resolvable via Mix.Task.run
        # inside an alias.
        "cmd mix hex.audit",
        "quality.ci"
      ]
    ]
  end

  defp package do
    [
      description:
        "ISO 3166 country data for Elixir: subdivisions, major cities, currencies, languages, " <>
          "international unions, time zones and country name translations in 23 locales.",
      maintainers: ["BeamLab"],
      licenses: ["MIT"],
      # Hex packages files from disk, not git, so the local dialyzer PLT
      # (priv/plts, ~3 MB) would otherwise ship with every release.
      exclude_patterns: [~r"^priv/plts"],
      links: %{"GitHub" => "https://github.com/BeamLabEU/beamlab_countries"}
    ]
  end
end
