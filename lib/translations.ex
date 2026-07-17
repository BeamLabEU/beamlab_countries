defmodule BeamLabCountries.Translations do
  @moduledoc """
  Module for looking up country names in different languages.

  Supports 15 languages: ar, de, en, es, fr, it, ja, ko, nl, pl, pt, ru, sv, uk, zh

  ## Examples

      iex> BeamLabCountries.Translations.get_name("PL", "de")
      "Polen"

      iex> BeamLabCountries.Translations.get_name("US", "ja")
      "米国"

      iex> BeamLabCountries.Translations.get_name("DE", "pl")
      "Niemcy"

  """

  @locales_path Path.join([:code.priv_dir(:beamlab_countries), "data", "locales"])
  @supported_locales ~w(ar de en es fr it ja ko nl pl pt ru sv uk zh)

  # Load all locale files at compile time
  @translations @supported_locales
                |> Enum.map(fn locale ->
                  path = Path.join(@locales_path, "#{locale}.json")
                  @external_resource path
                  data = path |> File.read!() |> JSON.decode!()
                  {locale, data}
                end)
                |> Map.new()

  @doc """
  Returns the country name in the specified language.

  ## Examples

      iex> BeamLabCountries.Translations.get_name("PL", "en")
      "Poland"

      iex> BeamLabCountries.Translations.get_name("PL", "de")
      "Polen"

      iex> BeamLabCountries.Translations.get_name("JP", "zh")
      "日本"

      iex> BeamLabCountries.Translations.get_name("XX", "en")
      nil

  """
  @spec get_name(String.t(), String.t()) :: String.t() | nil
  def get_name(country_code, locale) when is_binary(country_code) and is_binary(locale) do
    code = String.upcase(country_code)
    loc = String.downcase(locale)

    case Map.get(@translations, loc) do
      nil -> nil
      locale_data -> Map.get(locale_data, code)
    end
  end

  @doc """
  Returns the country name in all supported languages.

  ## Examples

      iex> names = BeamLabCountries.Translations.get_all_names("PL")
      iex> names["en"]
      "Poland"
      iex> names["de"]
      "Polen"

  """
  @spec get_all_names(String.t()) :: %{optional(String.t()) => String.t()}
  def get_all_names(country_code) when is_binary(country_code) do
    code = String.upcase(country_code)

    @translations
    |> Enum.map(fn {locale, data} -> {locale, Map.get(data, code)} end)
    |> Enum.reject(fn {_locale, name} -> is_nil(name) end)
    |> Map.new()
  end

  @doc """
  Returns list of supported locale codes.

  ## Examples

      iex> "en" in BeamLabCountries.Translations.supported_locales()
      true

      iex> "pl" in BeamLabCountries.Translations.supported_locales()
      true

  """
  @spec supported_locales() :: [String.t()]
  def supported_locales do
    @supported_locales
  end

  @doc """
  Checks if a locale is supported.

  ## Examples

      iex> BeamLabCountries.Translations.locale_supported?("en")
      true

      iex> BeamLabCountries.Translations.locale_supported?("xx")
      false

  """
  @spec locale_supported?(String.t()) :: boolean()
  def locale_supported?(locale) when is_binary(locale) do
    String.downcase(locale) in @supported_locales
  end
end
