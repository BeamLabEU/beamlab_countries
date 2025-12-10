defmodule PkCountries do
  @moduledoc """
  Module for providing countries related functions.
  """

  @doc """
  Returns all countries.
  """
  def all do
    countries()
  end

  @doc """
  Returns one country given its alpha2 country code, or `nil` if not found.

  ## Examples

      iex> %PkCountries.Country{name: name} = PkCountries.get("PL")
      iex> name
      "Poland"

      iex> PkCountries.get("INVALID")
      nil

  """
  def get(country_code) when is_binary(country_code) do
    Map.get(countries_by_alpha2(), String.upcase(country_code))
  end

  @doc """
  Returns one country given its alpha3 country code, or `nil` if not found.

  ## Examples

      iex> %PkCountries.Country{name: name} = PkCountries.get_by_alpha3("POL")
      iex> name
      "Poland"

      iex> PkCountries.get_by_alpha3("INVALID")
      nil

  """
  def get_by_alpha3(country_code) when is_binary(country_code) do
    Map.get(countries_by_alpha3(), String.upcase(country_code))
  end

  @doc """
  Returns one country given its alpha2 country code, or raises if not found.

  ## Examples

      iex> %PkCountries.Country{name: name} = PkCountries.get!("PL")
      iex> name
      "Poland"

  """
  def get!(country_code) do
    case get(country_code) do
      nil -> raise ArgumentError, "no country found for code: #{inspect(country_code)}"
      country -> country
    end
  end

  @doc """
  Returns one country matching the given attribute and value, or `nil` if not found.

  ## Examples

      iex> %PkCountries.Country{alpha2: alpha2} = PkCountries.get_by(:name, "Poland")
      iex> alpha2
      "PL"

      iex> PkCountries.get_by(:name, "Atlantis")
      nil

  """
  def get_by(attribute, value) do
    Enum.find(countries(), fn country ->
      country
      |> Map.get(attribute)
      |> equals_or_contains_in_list(value)
    end)
  end

  @doc """
  Filters countries by given attribute.

  Returns a list of `PkCountries.Country` structs

  ## Examples

      iex> countries = PkCountries.filter_by(:region, "Europe")
      iex> Enum.count(countries)
      51
      iex> Enum.map(countries, &Map.get(&1, :alpha2)) |> Enum.take(5)
      ["AD", "AL", "AT", "AX", "BA"]

      iex> countries = PkCountries.filter_by(:unofficial_names, "Reino Unido")
      iex> Enum.count(countries)
      1
      iex> Enum.map(countries, &Map.get(&1, :name)) |> List.first
      "United Kingdom of Great Britain and Northern Ireland"

  """
  def filter_by(attribute, value) do
    Enum.filter(countries(), fn country ->
      country
      |> Map.get(attribute)
      |> equals_or_contains_in_list(value)
    end)
  end

  defp equals_or_contains_in_list(nil, _), do: false
  defp equals_or_contains_in_list([], _), do: false

  defp equals_or_contains_in_list(list, value) when is_list(list) do
    normalized_value = normalize(value)
    Enum.any?(list, &(normalize(&1) == normalized_value))
  end

  defp equals_or_contains_in_list(attribute, value),
    do: normalize(attribute) == normalize(value)

  defp normalize(value) when is_integer(value),
    do: value |> Integer.to_string() |> normalize()

  defp normalize(value) when is_binary(value),
    do: value |> String.downcase() |> String.replace(~r/\s+/, "")

  defp normalize(value), do: value

  @doc """
  Checks if country for specific attribute and value exists.

  Returns boolean.

  ## Examples

      iex> PkCountries.exists?(:name, "Poland")
      true

      iex> PkCountries.exists?(:name, "Polande")
      false

  """
  def exists?(attribute, value) do
    Enum.any?(countries(), fn country ->
      country
      |> Map.get(attribute)
      |> equals_or_contains_in_list(value)
    end)
  end

  # -- Load countries from yaml files once on compile time ---

  @countries PkCountries.Loader.load()
  @countries_by_alpha2 Map.new(@countries, &{String.upcase(&1.alpha2), &1})
  @countries_by_alpha3 Map.new(@countries, &{String.upcase(&1.alpha3), &1})

  defp countries, do: @countries
  defp countries_by_alpha2, do: @countries_by_alpha2
  defp countries_by_alpha3, do: @countries_by_alpha3
end
