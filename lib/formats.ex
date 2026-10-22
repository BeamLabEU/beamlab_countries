defmodule BeamLabCountries.Formats do
  @moduledoc """
  Formats numbers, dates and money the way a country writes them, using the
  `decimal_separator`, `thousands_separator`, `date_format` and `currency_format`
  fields of `BeamLabCountries.Country`.

  Every function takes a `%BeamLabCountries.Country{}` or an alpha2 code and returns `nil`
  for an unknown code. Separators are CLDR's, so some are non-breaking spaces (`"\\u00A0"`
  or `"\\u202F"`). Negative numbers get an ASCII `-` in front of the whole value.

  One format per country is used, taken from its main language, and digits are grouped
  by thousands everywhere (no Indian lakh grouping), see `BeamLabCountries.Country`.
  """

  alias BeamLabCountries.Country
  alias BeamLabCountries.Currencies

  @date_tokens ~r/YYYY|MM|M|DD|D/

  @type country :: Country.t() | String.t()

  @doc """
  Formats a number with the country's separators.

  ## Options

    * `:decimals` - digits after the decimal separator. Default: `0` for integers, `2` for floats.
      Floats are rounded, integers are padded with zeros.

  ## Examples

      iex> BeamLabCountries.Formats.format_number("DE", 1234567.891)
      "1.234.567,89"

      iex> BeamLabCountries.Formats.format_number("GB", 1234567)
      "1,234,567"

      iex> BeamLabCountries.Formats.format_number("CH", -1234.5, decimals: 1)
      "-1'234.5"

      iex> BeamLabCountries.Formats.format_number("EE", 1234.5)
      "1\\u00A0234,50"

      iex> BeamLabCountries.Formats.format_number("XX", 1)
      nil

  Raises `ArgumentError` for a `:decimals` that is not a non-negative integer.
  """
  @spec format_number(country(), number(), keyword()) :: String.t() | nil
  def format_number(country, number, opts \\ []) when is_number(number) do
    case fetch(country) do
      nil ->
        nil

      country ->
        decimals = decimals!(opts, if(is_integer(number), do: 0, else: 2))
        {sign, digits} = digits(number, decimals)
        sign <> localize(digits, country)
    end
  end

  @doc """
  Formats a date with the country's short date pattern.

  Accepts a `Date`, `NaiveDateTime`, `DateTime`, or any map with `:year`, `:month` and `:day`.

  ## Examples

      iex> BeamLabCountries.Formats.format_date("DE", ~D[2026-03-07])
      "07.03.2026"

      iex> BeamLabCountries.Formats.format_date("US", ~D[2026-03-07])
      "3/7/2026"

      iex> BeamLabCountries.Formats.format_date("JP", ~N[2026-03-07 10:00:00])
      "2026/03/07"

      iex> BeamLabCountries.Formats.format_date("XX", ~D[2026-03-07])
      nil
  """
  @spec format_date(country(), Date.t() | %{year: integer(), month: 1..12, day: 1..31}) ::
          String.t() | nil
  def format_date(country, %{year: year, month: month, day: day}) do
    case fetch(country) do
      nil ->
        nil

      %Country{date_format: pattern} ->
        Regex.replace(@date_tokens, pattern, fn
          "YYYY" -> year |> Integer.to_string() |> String.pad_leading(4, "0")
          "MM" -> pad2(month)
          "M" -> Integer.to_string(month)
          "DD" -> pad2(day)
          "D" -> Integer.to_string(day)
        end)
    end
  end

  @doc """
  Formats an amount of money with the country's separators and currency pattern.

  The currency defaults to the country's `currency_code`, and its symbol and number of
  decimal places come from `BeamLabCountries.Currencies`. Returns `nil` for an unknown
  country, or when the country has no currency or the currency is unknown.

  ## Options

    * `:currency` - an ISO 4217 code to use instead of the country's own
    * `:native` - use the native symbol (`"ƒ"` rather than `"Afl."`). Default: `false`

  ## Examples

      iex> BeamLabCountries.Formats.format_currency("DE", 1234.56)
      "1.234,56\\u00A0€"

      iex> BeamLabCountries.Formats.format_currency("GB", 1234.56)
      "£1,234.56"

      iex> BeamLabCountries.Formats.format_currency("CH", 1234.56, currency: "CHF")
      "CHF\\u00A01'234.56"

      iex> BeamLabCountries.Formats.format_currency("US", -0.5, currency: "EUR")
      "-€0.50"

      iex> BeamLabCountries.Formats.format_currency("JP", 1234)
      "¥1,234"
  """
  @spec format_currency(country(), number(), keyword()) :: String.t() | nil
  def format_currency(country, amount, opts \\ []) when is_number(amount) do
    with %Country{currency_format: pattern} = country <- fetch(country),
         code when is_binary(code) <- Keyword.get(opts, :currency, country.currency_code),
         %{decimal_digits: decimals} = currency <- Currencies.get(code) do
      symbol =
        if Keyword.get(opts, :native, false), do: currency.symbol_native, else: currency.symbol

      {sign, digits} = digits(amount, decimals)

      sign <>
        (pattern
         |> String.replace("{{amount}}", localize(digits, country))
         |> String.replace("{{symbol}}", symbol))
    else
      _ -> nil
    end
  end

  # Absolute value as a "1234.50" string plus its sign. A negative amount that rounds to zero
  # has no sign. Also used by `Currencies.format/3`.
  @doc false
  @spec digits(number(), non_neg_integer()) :: {String.t(), String.t()}
  def digits(amount, decimals) when is_integer(amount) do
    sign = if amount < 0, do: "-", else: ""
    fraction = if decimals == 0, do: "", else: "." <> String.duplicate("0", decimals)
    {sign, Integer.to_string(abs(amount)) <> fraction}
  end

  def digits(amount, decimals) do
    rounded = Float.round(abs(amount), decimals)
    sign = if amount < 0 and rounded != 0, do: "-", else: ""
    {sign, :erlang.float_to_binary(rounded, decimals: decimals)}
  end

  # Groups the integer part by thousands with `separator` and joins the fraction with `decimal`.
  @doc false
  @spec group(String.t(), String.t(), String.t()) :: String.t()
  def group(digits, separator, decimal) do
    case String.split(digits, ".", parts: 2) do
      [integer, fraction] -> group_integer(integer, separator) <> decimal <> fraction
      [integer] -> group_integer(integer, separator)
    end
  end

  defp group_integer(integer, separator) do
    integer
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.map(&(&1 |> Enum.reverse() |> Enum.join()))
    |> Enum.reverse()
    |> Enum.join(separator)
  end

  defp localize(digits, %Country{} = country),
    do: group(digits, country.thousands_separator, country.decimal_separator)

  defp pad2(n), do: n |> Integer.to_string() |> String.pad_leading(2, "0")

  defp decimals!(opts, default) do
    case Keyword.get(opts, :decimals, default) do
      n when is_integer(n) and n >= 0 ->
        n

      other ->
        raise ArgumentError, ":decimals must be a non-negative integer, got: #{inspect(other)}"
    end
  end

  defp fetch(%Country{} = country), do: country
  defp fetch(code), do: BeamLabCountries.get(code)
end
