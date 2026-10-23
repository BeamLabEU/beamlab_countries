defmodule BeamLabCountries.Formats do
  @moduledoc """
  Formats numbers, dates and money the way a country writes them, using the
  `decimal_separator`, `thousands_separator`, `date_format` and `currency_format`
  fields of `BeamLabCountries.Country`.

  Every function takes a `%BeamLabCountries.Country{}` or an alpha2 code and returns `nil`
  for an unknown code. Separators are CLDR's, so some are non-breaking spaces (`"\\u00A0"`
  or `"\\u202F"`). Negative numbers get an ASCII `-` in front of the whole value.

  Numbers and amounts may be integers, floats or `Decimal` structs. Decimals are formatted
  exactly, never through a float, so they are the right input for prices and invoice totals.

  One format per country is used, taken from its main language, and digits are grouped
  by thousands everywhere (no Indian lakh grouping), see `BeamLabCountries.Country`.
  """

  alias BeamLabCountries.Country
  alias BeamLabCountries.Currencies

  @date_tokens ~r/YYYY|MM|M|DD|D/

  @type country :: Country.t() | String.t()

  # A `Decimal` struct, matched by shape so that the `decimal` package is not a dependency.
  @type decimal :: %{
          __struct__: Decimal,
          sign: 1 | -1,
          coef: non_neg_integer() | :NaN | :inf,
          exp: integer()
        }

  defguardp is_decimal(value) when is_struct(value, Decimal)

  @doc """
  Formats a number with the country's separators.

  ## Options

    * `:decimals` - digits after the decimal separator, from `0` to `15`.
      Default: `0` for integers, `2` for floats, and for a `Decimal` the number of
      decimal places it already has. Floats and decimals are rounded (half away from zero),
      integers are padded with zeros.

  ## Examples

      iex> BeamLabCountries.Formats.format_number("DE", 1234567.891)
      "1.234.567,89"

      iex> BeamLabCountries.Formats.format_number("GB", 1234567)
      "1,234,567"

      iex> BeamLabCountries.Formats.format_number("CH", -1234.5, decimals: 1)
      "-1'234.5"

      iex> BeamLabCountries.Formats.format_number("EE", 1234.5)
      "1\\u00A0234,50"

      iex> BeamLabCountries.Formats.format_number("DE", Decimal.new("30921.85"))
      "30.921,85"

      iex> BeamLabCountries.Formats.format_number("DE", Decimal.new("2.675"), decimals: 2)
      "2,68"

      iex> BeamLabCountries.Formats.format_number("XX", 1)
      nil

  Raises `ArgumentError` for a `:decimals` outside `0..15`, and for a `Decimal` that is
  `NaN` or infinite. Integers and decimals keep their full precision; floats use binary
  floating-point rounding (`2.675` is stored as `2.67499...`), so use a `Decimal` where
  the last digit matters.
  """
  @spec format_number(country(), number() | decimal(), keyword()) :: String.t() | nil
  def format_number(country, number, opts \\ [])
      when is_number(number) or is_decimal(number) do
    case fetch(country) do
      nil ->
        nil

      country ->
        decimals = decimals!(opts, default_decimals(number))
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
          "YYYY" -> format_year(year)
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

      iex> BeamLabCountries.Formats.format_currency("DE", Decimal.new("30921.855"))
      "30.921,86\\u00A0€"

  A `Decimal` amount is rounded to the currency's decimal places (half away from zero)
  without going through a float.
  """
  @spec format_currency(country(), number() | decimal(), keyword()) :: String.t() | nil
  def format_currency(country, amount, opts \\ [])
      when is_number(amount) or is_decimal(amount) do
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
  @spec digits(number() | decimal(), non_neg_integer()) :: {String.t(), String.t()}
  def digits(%{__struct__: Decimal, sign: sign, coef: coef, exp: exp}, decimals)
      when is_integer(coef) do
    scaled = round_scaled(coef, exp + decimals)

    digits =
      scaled |> Integer.to_string() |> String.pad_leading(decimals + 1, "0")

    {whole, fraction} = String.split_at(digits, String.length(digits) - decimals)
    digits = if decimals == 0, do: whole, else: whole <> "." <> fraction
    {if(sign == -1 and scaled != 0, do: "-", else: ""), digits}
  end

  def digits(%{__struct__: Decimal} = decimal, _decimals) do
    raise ArgumentError, "cannot format #{inspect(decimal)}: NaN and infinity have no digits"
  end

  def digits(amount, decimals) when is_integer(amount) do
    sign = if amount < 0, do: "-", else: ""
    {sign, integer_digits(abs(amount), decimals)}
  end

  def digits(amount, decimals) do
    rounded = Float.round(abs(amount), decimals)
    sign = if amount < 0 and rounded != 0, do: "-", else: ""

    # Fixed float output has a size limit in the VM. Large floats are whole numbers,
    # so convert them to integers to preserve their digits without that limit.
    digits =
      if rounded == trunc(rounded),
        do: integer_digits(trunc(rounded), decimals),
        else: :erlang.float_to_binary(rounded, decimals: decimals)

    {sign, digits}
  end

  # coef * 10^shift as an integer, rounding half away from zero when the shift is negative.
  defp round_scaled(coef, shift) when shift >= 0, do: coef * Integer.pow(10, shift)

  defp round_scaled(coef, shift) do
    divisor = Integer.pow(10, -shift)
    quotient = div(coef, divisor)
    if rem(coef, divisor) * 2 >= divisor, do: quotient + 1, else: quotient
  end

  defp default_decimals(%{__struct__: Decimal, coef: coef, exp: exp}) when is_integer(coef),
    do: max(-exp, 0)

  defp default_decimals(number) when is_integer(number) or is_struct(number, Decimal), do: 0
  defp default_decimals(number) when is_float(number), do: 2

  defp integer_digits(integer, decimals) do
    fraction = if decimals == 0, do: "", else: "." <> String.duplicate("0", decimals)
    Integer.to_string(integer) <> fraction
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

  defp format_year(year) do
    sign = if year < 0, do: "-", else: ""
    sign <> (year |> abs() |> Integer.to_string() |> String.pad_leading(4, "0"))
  end

  defp decimals!(opts, default) do
    case Keyword.get(opts, :decimals, default) do
      n when is_integer(n) and n in 0..15 ->
        n

      other ->
        raise ArgumentError, ":decimals must be an integer in 0..15, got: #{inspect(other)}"
    end
  end

  defp fetch(%Country{} = country), do: country
  defp fetch(code), do: BeamLabCountries.get(code)
end
