defmodule BeamLabCountries.Translations do
  @moduledoc """
  Module for looking up country names in different languages.

  Supports 23 languages: ar, cs, de, en, es, et, fr, hi, id, it, ja, ko, nl, pl, pt, ro, ru, sv, th, tr, uk, vi, zh

  ## Examples

      iex> BeamLabCountries.Translations.get_name("PL", "de")
      "Polen"

      iex> BeamLabCountries.Translations.get_name("US", "ja")
      "米国"

      iex> BeamLabCountries.Translations.get_name("DE", "pl")
      "Niemcy"

      iex> BeamLabCountries.Translations.get_name("EE", "et")
      "Eesti"

  """

  @locales_path Path.join([:code.priv_dir(:beamlab_countries), "data", "locales"])
  @locale_files @locales_path |> Path.join("*.json") |> Path.wildcard() |> Enum.sort()

  for file <- @locale_files do
    @external_resource file
  end

  # `@external_resource` only tracks files that already exist, so also
  # recompile when a locale file is added or removed.
  @files_hash :erlang.md5(@locale_files)

  @doc false
  def __mix_recompile__? do
    @locales_path
    |> Path.join("*.json")
    |> Path.wildcard()
    |> Enum.sort()
    |> :erlang.md5()
    |> Kernel.!=(@files_hash)
  end

  # Load all locale files at compile time
  @translations Map.new(@locale_files, fn path ->
                  {Path.basename(path, ".json"), path |> File.read!() |> JSON.decode!()}
                end)
  @supported_locales @translations |> Map.keys() |> Enum.sort()

  @doc """
  Returns the country name in the specified language.

  The locale is case-insensitive. A regional locale such as `"de-AT"` or `"pt_BR"` is
  reduced to its language (`"de"`, `"pt"`) when it is not supported as such.

  ## Options

    * `:fallback` - a locale to use when the country has no name in `locale`
      (including when `locale` is not supported). Defaults to `nil`, which returns `nil`.

  ## Examples

      iex> BeamLabCountries.Translations.get_name("PL", "en")
      "Poland"

      iex> BeamLabCountries.Translations.get_name("PL", "de")
      "Polen"

      iex> BeamLabCountries.Translations.get_name("PL", "de-AT")
      "Polen"

      iex> BeamLabCountries.Translations.get_name("JP", "zh")
      "日本"

      iex> BeamLabCountries.Translations.get_name("XX", "en")
      nil

      iex> BeamLabCountries.Translations.get_name("PL", "xx")
      nil

      iex> BeamLabCountries.Translations.get_name("PL", "xx", fallback: "en")
      "Poland"

  """
  @spec get_name(String.t(), String.t(), keyword()) :: String.t() | nil
  def get_name(country_code, locale, opts \\ [])

  def get_name(country_code, locale, opts) when is_binary(country_code) and is_binary(locale) do
    lookup(country_code, locale) || fallback(country_code, Keyword.get(opts, :fallback))
  end

  def get_name(_country_code, _locale, _opts), do: nil

  defp fallback(_country_code, nil), do: nil
  defp fallback(country_code, locale), do: lookup(country_code, locale)

  defp lookup(country_code, locale) do
    code = String.upcase(country_code)
    locale = locale |> String.downcase() |> String.replace("_", "-")

    case Map.fetch(@translations, locale) do
      {:ok, names} ->
        Map.get(names, code)

      :error ->
        [language | _] = String.split(locale, "-")
        @translations |> Map.get(language, %{}) |> Map.get(code)
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

  def get_all_names(_country_code), do: %{}

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

  def locale_supported?(_locale), do: false
end
