defmodule BeamLabCountries.Subdivisions do
  @moduledoc """
  Module for providing subdivisions related functions.

  Subdivision data is loaded at compile time, so lookups are fast
  and no filesystem access happens at runtime.
  """

  alias BeamLabCountries.Country
  alias BeamLabCountries.Subdivision

  # Load subdivisions from yaml files once on compile time
  @subdivisions BeamLabCountries.SubdivisionLoader.load()

  @doc """
  Returns all subdivisions for a country.

  Accepts a `BeamLabCountries.Country` struct or an alpha2 country code
  (case-insensitive). Returns an empty list when the country is unknown
  or has no subdivision data.

  ## Examples

      iex> BeamLabCountries.Subdivisions.all("PL") |> length()
      16

      iex> country = BeamLabCountries.get("BR")
      iex> BeamLabCountries.Subdivisions.all(country) |> length()
      27

      iex> BeamLabCountries.Subdivisions.all("XX")
      []

  """
  @spec all(Country.t() | String.t()) :: [Subdivision.t()]
  def all(%Country{alpha2: alpha2}), do: all(alpha2)

  def all(country_code) when is_binary(country_code) do
    @subdivisions
    |> Map.get(String.upcase(country_code), %{})
    |> Map.values()
  end

  @doc """
  Returns one subdivision by country and subdivision ID, or `nil` if not found.

  Accepts a `BeamLabCountries.Country` struct or an alpha2 country code.
  Both the country code and the subdivision ID are case-insensitive.

  ## Examples

      iex> BeamLabCountries.Subdivisions.get("US", "CA").name
      "California"

      iex> BeamLabCountries.Subdivisions.get("us", "ca").name
      "California"

      iex> BeamLabCountries.Subdivisions.get("US", "XX")
      nil

  """
  @spec get(Country.t() | String.t(), String.t()) :: Subdivision.t() | nil
  def get(%Country{alpha2: alpha2}, subdivision_id), do: get(alpha2, subdivision_id)

  def get(country_code, subdivision_id)
      when is_binary(country_code) and is_binary(subdivision_id) do
    @subdivisions
    |> Map.get(String.upcase(country_code), %{})
    |> Map.get(String.upcase(subdivision_id))
  end
end
