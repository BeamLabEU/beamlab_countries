defmodule BeamLabCountries do
  @moduledoc """
  Module for providing countries related functions.

  Lookup functions (`get/1`, `get_by_alpha3/1`) return `nil` for anything that is
  not a known code, including non-string input. `get_by/2`, `filter_by/1,2` and
  `exists?/2` raise `ArgumentError` for attributes that are not `BeamLabCountries.Country`
  fields, so a typo does not silently produce an empty result.
  """

  alias BeamLabCountries.Country
  alias BeamLabCountries.Normalizer

  @attributes Country |> struct() |> Map.keys() |> List.delete(:__struct__) |> Enum.sort()

  @doc """
  Returns all countries.
  """
  @spec all() :: [Country.t()]
  def all do
    countries()
  end

  @doc """
  Returns the total number of countries.

  ## Examples

      iex> BeamLabCountries.count()
      250

  """
  @spec count() :: non_neg_integer()
  def count do
    length(countries())
  end

  @doc """
  Returns one country given its alpha2 country code, or `nil` if not found.

  ## Examples

      iex> %BeamLabCountries.Country{name: name} = BeamLabCountries.get("PL")
      iex> name
      "Poland"

      iex> BeamLabCountries.get("INVALID")
      nil

  """
  @spec get(String.t()) :: Country.t() | nil
  def get(country_code) when is_binary(country_code) do
    Map.get(countries_by_alpha2(), String.upcase(country_code))
  end

  def get(_country_code), do: nil

  @doc """
  Returns one country given its alpha3 country code, or `nil` if not found.

  ## Examples

      iex> %BeamLabCountries.Country{name: name} = BeamLabCountries.get_by_alpha3("POL")
      iex> name
      "Poland"

      iex> BeamLabCountries.get_by_alpha3("INVALID")
      nil

  """
  @spec get_by_alpha3(String.t()) :: Country.t() | nil
  def get_by_alpha3(country_code) when is_binary(country_code) do
    Map.get(countries_by_alpha3(), String.upcase(country_code))
  end

  def get_by_alpha3(_country_code), do: nil

  @doc """
  Returns one country given its alpha2 country code, or raises if not found.

  ## Examples

      iex> %BeamLabCountries.Country{name: name} = BeamLabCountries.get!("PL")
      iex> name
      "Poland"

  """
  @spec get!(String.t()) :: Country.t()
  def get!(country_code) do
    case get(country_code) do
      nil -> raise ArgumentError, "no country found for code: #{inspect(country_code)}"
      country -> country
    end
  end

  @doc """
  Returns one country matching the given attribute and value, or `nil` if not found.

  ## Examples

      iex> %BeamLabCountries.Country{alpha2: alpha2} = BeamLabCountries.get_by(:name, "Poland")
      iex> alpha2
      "PL"

      iex> BeamLabCountries.get_by(:name, "Atlantis")
      nil

  """
  @spec get_by(atom(), term()) :: Country.t() | nil
  def get_by(attribute, value) do
    attribute = validate_attribute!(attribute)

    value = Normalizer.normalize(value)
    indexed() |> Enum.find(&matches?(&1, attribute, value)) |> country_of()
  end

  @doc """
  Filters countries by given attribute.

  Returns a list of `BeamLabCountries.Country` structs

  ## Single attribute

      iex> countries = BeamLabCountries.filter_by(:region, "Europe")
      iex> Enum.count(countries)
      51
      iex> Enum.map(countries, &Map.get(&1, :alpha2)) |> Enum.take(5)
      ["AD", "AL", "AT", "AX", "BA"]

      iex> countries = BeamLabCountries.filter_by(:unofficial_names, "Reino Unido")
      iex> Enum.count(countries)
      1
      iex> Enum.map(countries, &Map.get(&1, :name)) |> List.first
      "United Kingdom of Great Britain and Northern Ireland"

  ## Multiple attributes

      iex> countries = BeamLabCountries.filter_by(region: "Europe", eu_member: true)
      iex> length(countries)
      26

      iex> countries = BeamLabCountries.filter_by(region: "Europe", eea_member: true)
      iex> length(countries)
      30

  """
  @spec filter_by(atom(), term()) :: [Country.t()]
  def filter_by(attribute, value) when is_atom(attribute) do
    attribute = validate_attribute!(attribute)

    value = Normalizer.normalize(value)
    indexed() |> Enum.filter(&matches?(&1, attribute, value)) |> Enum.map(&elem(&1, 0))
  end

  @spec filter_by(keyword()) :: [Country.t()]
  def filter_by(criteria) when is_list(criteria) do
    criteria =
      Enum.map(criteria, fn {attribute, value} ->
        {validate_attribute!(attribute), Normalizer.normalize(value)}
      end)

    indexed()
    |> Enum.filter(fn entry ->
      Enum.all?(criteria, fn {attribute, value} -> matches?(entry, attribute, value) end)
    end)
    |> Enum.map(&elem(&1, 0))
  end

  # `value` must already be normalized
  defp matches?({_country, normalized}, attribute, value) do
    case Map.fetch!(normalized, attribute) do
      nil -> false
      list when is_list(list) -> value in list
      attribute_value -> attribute_value == value
    end
  end

  defp validate_attribute!(attribute) when attribute in @attributes, do: attribute

  defp validate_attribute!(attribute) do
    raise ArgumentError,
          "unknown country attribute: #{inspect(attribute)}, expected one of: " <>
            Enum.map_join(@attributes, ", ", &inspect/1)
  end

  @doc """
  Returns all EU member countries.

  ## Examples

      iex> eu = BeamLabCountries.eu_members()
      iex> length(eu)
      27
      iex> Enum.map(eu, &Map.get(&1, :alpha2)) |> Enum.take(3)
      ["AT", "BE", "BG"]

  """
  @spec eu_members() :: [Country.t()]
  def eu_members do
    filter_by(:eu_member, true)
  end

  @doc """
  Checks if country for specific attribute and value exists.

  Returns boolean.

  ## Examples

      iex> BeamLabCountries.exists?(:name, "Poland")
      true

      iex> BeamLabCountries.exists?(:name, "Polande")
      false

  """
  @spec exists?(atom(), term()) :: boolean()
  def exists?(attribute, value) do
    attribute = validate_attribute!(attribute)

    value = Normalizer.normalize(value)
    Enum.any?(indexed(), &matches?(&1, attribute, value))
  end

  # -- Load countries from yaml files once on compile time ---

  @countries BeamLabCountries.Loader.load()
  @countries_by_alpha2 Map.new(@countries, &{String.upcase(&1.alpha2), &1})
  @countries_by_alpha3 Map.new(@countries, &{String.upcase(&1.alpha3), &1})

  # Every attribute value normalized once, so filtering does no string work per call
  @indexed Enum.map(@countries, fn country ->
             normalized =
               Map.new(@attributes, &{&1, Normalizer.normalize(Map.fetch!(country, &1))})

             {country, normalized}
           end)

  defp countries, do: @countries
  defp indexed, do: @indexed
  defp country_of({country, _normalized}), do: country
  defp country_of(nil), do: nil
  defp countries_by_alpha2, do: @countries_by_alpha2
  defp countries_by_alpha3, do: @countries_by_alpha3
end
