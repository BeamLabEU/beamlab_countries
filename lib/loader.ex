defmodule BeamLabCountries.Loader do
  @moduledoc false

  alias BeamLabCountries.Country

  @doc """
  Loads all country data from YAML files at compile time.
  """
  def load do
    data_path("countries.yaml")
    |> YamlElixir.read_from_file!()
    |> Enum.map(fn code ->
      data_path("countries/#{code}.yaml")
      |> YamlElixir.read_from_file!()
      |> Map.fetch!(code)
      |> convert_country()
    end)
  end

  defp data_path(path) do
    Path.join([:code.priv_dir(:beamlab_countries), "data", path])
  end

  defp convert_country(data) do
    %Country{
      number: data["number"],
      alpha2: data["alpha2"],
      alpha3: data["alpha3"],
      currency: data["currency"],
      name: data["name"],
      flag: data["flag"],
      unofficial_names: data["unofficial_names"],
      continent: data["continent"],
      region: data["region"],
      subregion: data["subregion"],
      geo: atomize_keys(data["geo"]),
      world_region: data["world_region"],
      country_code: data["country_code"],
      national_destination_code_lengths: data["national_destination_code_lengths"],
      national_number_lengths: data["national_number_lengths"],
      international_prefix: data["international_prefix"],
      national_prefix: data["national_prefix"],
      ioc: data["ioc"],
      gec: data["gec"],
      un_locode: data["un_locode"],
      languages_official: data["languages_official"],
      languages_spoken: data["languages_spoken"],
      language_locales: atomize_keys(data["language_locales"]),
      nationality: data["nationality"],
      address_format: data["address_format"],
      dissolved_on: data["dissolved_on"],
      eu_member: data["eu_member"],
      eea_member: data["eea_member"],
      alt_currency: data["alt_currency"],
      vat_rates: normalize_vat_rates(data["vat_rates"]),
      postal_code: data["postal_code"],
      currency_code: data["currency_code"],
      start_of_week: data["start_of_week"]
    }
  end

  defp atomize_keys(nil), do: nil

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), atomize_keys(v)} end)
  end

  defp atomize_keys(value), do: value

  # VAT rates normalization to handle charlist representation issue.
  #
  # When YAML parser reads single-digit numbers in lists like `reduced: [9]`,
  # Elixir represents them as charlists (e.g., ~c"\t" for [9]) because lists
  # of integers 0-127 are displayed as charlists. This normalizes all rate
  # values to ensure consistent integer/float representation.

  defp normalize_vat_rates(nil), do: nil

  defp normalize_vat_rates(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), normalize_vat_value(v)} end)
  end

  defp normalize_vat_value(nil), do: nil

  defp normalize_vat_value(list) when is_list(list) do
    Enum.map(list, &ensure_numeric/1)
  end

  defp normalize_vat_value(value), do: ensure_numeric(value)

  defp ensure_numeric(n) when is_integer(n), do: n
  defp ensure_numeric(n) when is_float(n), do: n
  defp ensure_numeric(nil), do: nil
  defp ensure_numeric(_), do: nil
end
