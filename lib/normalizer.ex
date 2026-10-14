defmodule BeamLabCountries.Normalizer do
  @moduledoc false

  # Case- and whitespace-insensitive form of an attribute value, used so that
  # `BeamLabCountries.filter_by/2` and friends can compare against values that
  # were normalized once at compile time.

  @spec normalize(term()) :: term()
  def normalize(value) when is_integer(value), do: value |> Integer.to_string() |> normalize()

  def normalize(value) when is_binary(value),
    do: value |> String.downcase() |> String.split() |> Enum.join()

  def normalize(value) when is_list(value), do: Enum.map(value, &normalize/1)
  def normalize(value), do: value
end
