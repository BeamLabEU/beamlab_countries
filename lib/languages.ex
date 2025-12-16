defmodule BeamLabCountries.Languages do
  @moduledoc """
  Module for looking up language names from ISO 639-1 codes and regional locales.

  This module provides two levels of language data:

  1. **Base Languages** - ISO 639-1 codes (e.g., "en", "es", "de") with 184 languages
  2. **Locales** - Regional variants (e.g., "en-US", "es-ES", "pt-BR") combining language and country

  ## Base Language Examples

      iex> BeamLabCountries.Languages.get_name("en")
      "English"

      iex> BeamLabCountries.Languages.get("de")
      %BeamLabCountries.Language{code: "de", name: "German", native_name: "Deutsch", family: "Indo-European"}

  ## Locale Examples

      locale = BeamLabCountries.Languages.get_locale("en-US")
      locale.name
      #=> "English (United States)"

      BeamLabCountries.Languages.all_locales() |> length()
      #=> 85

  ## Country-Language Associations

      BeamLabCountries.Languages.country_names_for_language("en")
      #=> ["United States of America", "United Kingdom", ...]

  """

  alias BeamLabCountries.Language
  alias BeamLabCountries.Locale

  # Load base languages from JSON at compile time
  @languages_path Path.join([:code.priv_dir(:beamlab_countries), "data", "languages.json"])
  @external_resource @languages_path

  @languages @languages_path
             |> File.read!()
             |> JSON.decode!()
             |> Map.new(fn {code, data} -> {code, data} end)

  # Load locales from JSON at compile time
  @locales_path Path.join([:code.priv_dir(:beamlab_countries), "data", "locales.json"])
  @external_resource @locales_path

  @raw_locales @locales_path
               |> File.read!()
               |> JSON.decode!()

  # Build country lookup for enriching locales with flag and country_name
  # We need to defer this to runtime since BeamLabCountries may not be compiled yet
  defp get_country(code) do
    BeamLabCountries.get(code)
  end

  # Build locales with enriched data (flag, country_name from Country)
  @locales @raw_locales
           |> Enum.map(fn {code, data} ->
             {code,
              %{
                "code" => code,
                "base" => data["base"],
                "region" => data["region"],
                "name" => data["name"],
                "nativeName" => data["nativeName"]
              }}
           end)
           |> Map.new()

  # Build index of locale codes by base language code
  @locales_by_base @raw_locales
                   |> Enum.group_by(fn {_code, data} -> data["base"] end, fn {code, _data} ->
                     code
                   end)

  # ============================================================================
  # Base Language Functions (existing API - backward compatible)
  # ============================================================================

  @doc """
  Returns the English name for a language code.

  ## Examples

      iex> BeamLabCountries.Languages.get_name("en")
      "English"

      iex> BeamLabCountries.Languages.get_name("de")
      "German"

      iex> BeamLabCountries.Languages.get_name("ja")
      "Japanese"

  """
  def get_name(code) when is_binary(code) do
    case Map.get(@languages, String.downcase(code)) do
      nil -> nil
      data -> data["name"]
    end
  end

  @doc """
  Returns the native name for a language code.

  ## Examples

      iex> BeamLabCountries.Languages.get_native_name("en")
      "English"

      iex> BeamLabCountries.Languages.get_native_name("de")
      "Deutsch"

      iex> BeamLabCountries.Languages.get_native_name("ja")
      "日本語 (にほんご)"

  """
  def get_native_name(code) when is_binary(code) do
    case Map.get(@languages, String.downcase(code)) do
      nil -> nil
      data -> data["nativeName"]
    end
  end

  @doc """
  Returns full language info as a Language struct for a language code.

  ## Examples

      iex> BeamLabCountries.Languages.get("en")
      %BeamLabCountries.Language{code: "en", name: "English", native_name: "English", family: "Indo-European"}

      iex> BeamLabCountries.Languages.get("invalid")
      nil

  """
  def get(code) when is_binary(code) do
    case Map.get(@languages, String.downcase(code)) do
      nil ->
        nil

      data ->
        %Language{
          code: data["639-1"],
          name: data["name"],
          native_name: data["nativeName"],
          family: data["family"]
        }
    end
  end

  @doc """
  Returns all languages as Language structs.

  ## Examples

      iex> languages = BeamLabCountries.Languages.all()
      iex> length(languages)
      184
      iex> %BeamLabCountries.Language{} = hd(languages)

  """
  def all do
    @languages
    |> Enum.map(fn {_code, data} ->
      %Language{
        code: data["639-1"],
        name: data["name"],
        native_name: data["nativeName"],
        family: data["family"]
      }
    end)
    |> Enum.sort_by(& &1.name)
  end

  @doc """
  Returns all language codes.

  ## Examples

      iex> "en" in BeamLabCountries.Languages.all_codes()
      true

  """
  def all_codes do
    Map.keys(@languages)
  end

  @doc """
  Returns the count of supported base languages.

  ## Examples

      iex> BeamLabCountries.Languages.count()
      184

  """
  def count do
    map_size(@languages)
  end

  @doc """
  Checks if a base language code is valid.

  ## Examples

      iex> BeamLabCountries.Languages.valid?("en")
      true

      iex> BeamLabCountries.Languages.valid?("invalid")
      false

  """
  def valid?(code) when is_binary(code) do
    Map.has_key?(@languages, String.downcase(code))
  end

  # ============================================================================
  # Locale Functions (new API)
  # ============================================================================

  @doc """
  Returns a Locale struct for the given locale code.

  Locale codes can be either:
  - Full locale codes like "en-US", "es-ES", "pt-BR"
  - Base language codes like "ja", "ko", "ar" (for languages without regional variants in the data)

  The flag and country_name are derived from the Country data based on the region code.

  ## Examples

      iex> locale = BeamLabCountries.Languages.get_locale("en-US")
      iex> locale.code
      "en-US"
      iex> locale.name
      "English (United States)"
      iex> locale.flag
      "🇺🇸"

      iex> BeamLabCountries.Languages.get_locale("invalid")
      nil

  """
  def get_locale(code) when is_binary(code) do
    case Map.get(@locales, code) do
      nil ->
        nil

      data ->
        country = get_country(data["region"])

        %Locale{
          code: data["code"],
          base_code: data["base"],
          region_code: data["region"],
          name: data["name"],
          native_name: data["nativeName"],
          flag: country && country.flag,
          country_name: country && country.name,
          continent: country && country.continent,
          region: country && country.region,
          subregion: country && country.subregion
        }
    end
  end

  @doc """
  Returns all locales as Locale structs, sorted by name.

  ## Examples

      iex> locales = BeamLabCountries.Languages.all_locales()
      iex> length(locales) > 0
      true
      iex> %BeamLabCountries.Locale{} = hd(locales)

  """
  def all_locales do
    @locales
    |> Enum.map(fn {_code, data} ->
      country = get_country(data["region"])

      %Locale{
        code: data["code"],
        base_code: data["base"],
        region_code: data["region"],
        name: data["name"],
        native_name: data["nativeName"],
        flag: country && country.flag,
        country_name: country && country.name,
        continent: country && country.continent,
        region: country && country.region,
        subregion: country && country.subregion
      }
    end)
    |> Enum.sort_by(& &1.name)
  end

  @doc """
  Returns all locale codes.

  ## Examples

      iex> "en-US" in BeamLabCountries.Languages.all_locale_codes()
      true

  """
  def all_locale_codes do
    Map.keys(@locales)
  end

  @doc """
  Returns the count of supported locales.

  ## Examples

      iex> BeamLabCountries.Languages.locale_count()
      85

  """
  def locale_count do
    map_size(@locales)
  end

  @doc """
  Returns all locales for a given base language code.

  ## Examples

      iex> locales = BeamLabCountries.Languages.locales_for_language("en")
      iex> Enum.map(locales, & &1.code)
      ["en-AU", "en-CA", "en-GB", "en-US"]

      iex> locales = BeamLabCountries.Languages.locales_for_language("es")
      iex> length(locales)
      4

  """
  def locales_for_language(base_code) when is_binary(base_code) do
    locale_codes = Map.get(@locales_by_base, String.downcase(base_code), [])

    locale_codes
    |> Enum.map(&get_locale/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(& &1.name)
  end

  @doc """
  Checks if a locale code is valid.

  ## Examples

      iex> BeamLabCountries.Languages.valid_locale?("en-US")
      true

      iex> BeamLabCountries.Languages.valid_locale?("invalid")
      false

  """
  def valid_locale?(code) when is_binary(code) do
    Map.has_key?(@locales, code)
  end

  @doc """
  Parses a locale code into its base language code and region code.

  ## Examples

      iex> BeamLabCountries.Languages.parse_locale("en-US")
      {"en", "US"}

      iex> BeamLabCountries.Languages.parse_locale("pt-BR")
      {"pt", "BR"}

      iex> BeamLabCountries.Languages.parse_locale("ja")
      {"ja", nil}

  """
  def parse_locale(code) when is_binary(code) do
    case String.split(code, "-", parts: 2) do
      [base, region] -> {String.downcase(base), region}
      [base] -> {String.downcase(base), nil}
    end
  end

  # ============================================================================
  # Country-Language Association Functions
  # ============================================================================

  @doc """
  Returns all countries where a language is spoken.

  Uses the `languages_spoken` field from Country data.

  ## Examples

      iex> countries = BeamLabCountries.Languages.countries_for_language("en")
      iex> length(countries) > 50
      true
      iex> "United States of America" in Enum.map(countries, & &1.name)
      true

  """
  def countries_for_language(lang_code) when is_binary(lang_code) do
    code = String.downcase(lang_code)

    BeamLabCountries.all()
    |> Enum.filter(fn country ->
      languages = country.languages_spoken || []
      code in Enum.map(languages, &String.downcase/1)
    end)
    |> Enum.sort_by(& &1.name)
  end

  @doc """
  Returns country names where a language is spoken.

  ## Examples

      iex> names = BeamLabCountries.Languages.country_names_for_language("en")
      iex> "United States of America" in names
      true
      iex> "United Kingdom of Great Britain and Northern Ireland" in names
      true

  """
  def country_names_for_language(lang_code) when is_binary(lang_code) do
    lang_code
    |> countries_for_language()
    |> Enum.map(& &1.name)
  end

  @doc """
  Returns flags for countries where a language is spoken.

  ## Examples

      iex> flags = BeamLabCountries.Languages.flags_for_language("en")
      iex> "🇺🇸" in flags
      true
      iex> "🇬🇧" in flags
      true

  """
  def flags_for_language(lang_code) when is_binary(lang_code) do
    lang_code
    |> countries_for_language()
    |> Enum.map(& &1.flag)
    |> Enum.reject(&is_nil/1)
  end
end
