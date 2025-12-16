defmodule BeamLabCountries.Unions do
  @moduledoc """
  Module for working with international unions, organizations, and country groupings.

  This module provides functions to query unions such as the European Union, NATO,
  G7, ASEAN, and other international organizations.

  ## Examples

      # Get all unions
      BeamLabCountries.Unions.all()

      # Get a specific union
      BeamLabCountries.Unions.get("eu")

      # Check if a country is a member of a union
      BeamLabCountries.Unions.member?("DE", "eu")

      # Get all unions a country belongs to
      BeamLabCountries.Unions.for_country("DE")

  """

  alias BeamLabCountries.Union

  # Load unions from yaml files once at compile time
  @unions BeamLabCountries.UnionLoader.load()
  @unions_by_code Map.new(@unions, &{String.downcase(&1.code), &1})

  # Build reverse lookup: country_alpha2 -> list of union codes
  @unions_by_country @unions
                     |> Enum.flat_map(fn union ->
                       Enum.map(union.members, fn member ->
                         {String.upcase(member), union.code}
                       end)
                     end)
                     |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))

  @doc """
  Returns all unions.

  ## Examples

      iex> unions = BeamLabCountries.Unions.all()
      iex> length(unions) > 0
      true

  """
  @spec all() :: [Union.t()]
  def all do
    @unions
  end

  @doc """
  Returns the total number of unions.

  ## Examples

      iex> BeamLabCountries.Unions.count()
      13

  """
  @spec count() :: non_neg_integer()
  def count do
    length(@unions)
  end

  @doc """
  Returns one union given its code, or `nil` if not found.

  ## Examples

      iex> %BeamLabCountries.Union{name: name} = BeamLabCountries.Unions.get("eu")
      iex> name
      "European Union"

      iex> BeamLabCountries.Unions.get("invalid")
      nil

  """
  @spec get(String.t()) :: Union.t() | nil
  def get(union_code) when is_binary(union_code) do
    Map.get(@unions_by_code, String.downcase(union_code))
  end

  @doc """
  Returns one union given its code, or raises if not found.

  ## Examples

      iex> %BeamLabCountries.Union{name: name} = BeamLabCountries.Unions.get!("eu")
      iex> name
      "European Union"

  """
  @spec get!(String.t()) :: Union.t()
  def get!(union_code) do
    case get(union_code) do
      nil -> raise ArgumentError, "no union found for code: #{inspect(union_code)}"
      union -> union
    end
  end

  @doc """
  Returns all unions that a country belongs to.

  ## Examples

      iex> unions = BeamLabCountries.Unions.for_country("DE")
      iex> "eu" in Enum.map(unions, & &1.code)
      true

  """
  @spec for_country(String.t()) :: [Union.t()]
  def for_country(country_code) when is_binary(country_code) do
    case Map.get(@unions_by_country, String.upcase(country_code)) do
      nil -> []
      union_codes -> Enum.map(union_codes, &get/1)
    end
  end

  @doc """
  Returns union codes that a country belongs to.

  ## Examples

      iex> codes = BeamLabCountries.Unions.codes_for_country("DE")
      iex> "eu" in codes
      true

  """
  @spec codes_for_country(String.t()) :: [String.t()]
  def codes_for_country(country_code) when is_binary(country_code) do
    Map.get(@unions_by_country, String.upcase(country_code), [])
  end

  @doc """
  Filters unions by given attribute and value.

  ## Examples

      iex> unions = BeamLabCountries.Unions.filter_by(:type, :military)
      iex> Enum.any?(unions, &(&1.code == "nato"))
      true

  """
  @spec filter_by(atom(), any()) :: [Union.t()]
  def filter_by(attribute, value) do
    Enum.filter(@unions, fn union ->
      Map.get(union, attribute) == value
    end)
  end

  @doc """
  Checks if a union exists.

  ## Examples

      iex> BeamLabCountries.Unions.exists?("eu")
      true

      iex> BeamLabCountries.Unions.exists?("invalid")
      false

  """
  @spec exists?(String.t()) :: boolean()
  def exists?(union_code) when is_binary(union_code) do
    Map.has_key?(@unions_by_code, String.downcase(union_code))
  end

  @doc """
  Checks if a country is a member of a union.

  ## Examples

      iex> BeamLabCountries.Unions.member?("DE", "eu")
      true

      iex> BeamLabCountries.Unions.member?("US", "eu")
      false

  """
  @spec member?(String.t(), String.t()) :: boolean()
  def member?(country_code, union_code)
      when is_binary(country_code) and is_binary(union_code) do
    case get(union_code) do
      nil -> false
      union -> String.upcase(country_code) in union.members
    end
  end

  @doc """
  Returns all member countries of a union as Country structs.

  ## Examples

      iex> countries = BeamLabCountries.Unions.member_countries("eu")
      iex> length(countries)
      27

  """
  @spec member_countries(String.t()) :: [BeamLabCountries.Country.t()]
  def member_countries(union_code) when is_binary(union_code) do
    case get(union_code) do
      nil -> []
      union -> Enum.map(union.members, &BeamLabCountries.get/1) |> Enum.reject(&is_nil/1)
    end
  end
end
