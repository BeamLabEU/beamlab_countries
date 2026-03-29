defmodule BeamLabCountries.Random do
  @moduledoc """
  Module for returning random countries.
  """

  @doc """
  Returns a random country.

  ## Examples

      iex> %BeamLabCountries.Country{} = BeamLabCountries.Random.country()

  """
  @spec country() :: BeamLabCountries.Country.t()
  def country do
    BeamLabCountries.all() |> Enum.random()
  end

  @doc """
  Returns a random country flag emoji.

  ## Examples

      iex> BeamLabCountries.Random.flag()
      "\\xF0\\x9F\\x87\\xBA\\x93"

  """
  @spec flag() :: String.t()
  def flag do
    BeamLabCountries.all()
    |> Enum.filter(&(not is_nil(&1.flag)))
    |> Enum.random()
    |> Map.get(:flag)
  end
end
