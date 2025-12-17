defmodule BeamLabCountries.MixProject do
  use Mix.Project

  @source_url "https://github.com/BeamLabEU/beamlab_countries"
  @version "1.0.5"

  def project do
    [
      app: :beamlab_countries,
      version: @version,
      elixir: "~> 1.18",
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:yaml_elixir, "~> 2.12"},
      {:ex_doc, "~> 0.39", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp package do
    [
      description:
        "BeamLabCountries is a collection of all sorts of useful information for every country " <>
          "in the [ISO 3166](https://wikipedia.org/wiki/ISO_3166) standard. It includes country data, " <>
          "subdivisions (states/provinces), international organizations, language information, and country name translations.",
      maintainers: ["BeamLab"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/BeamLabEU/beamlab_countries"}
    ]
  end
end
