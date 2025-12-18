defmodule BeamLabCountries.Currencies do
  @moduledoc """
  Module for looking up currency information from ISO 4217 codes.

  This module provides currency data including names, symbols, and decimal precision
  for 164 world currencies. Data is loaded at compile time for fast lookups.

  ## Examples

      iex> BeamLabCountries.Currencies.get("USD")
      %BeamLabCountries.Currency{code: "USD", name: "US Dollar", name_plural: "US dollars", symbol: "$", symbol_native: "$", decimal_digits: 2}

      iex> BeamLabCountries.Currencies.symbol("EUR")
      "€"

      iex> BeamLabCountries.Currencies.for_country("JP")
      %BeamLabCountries.Currency{code: "JPY", name: "Japanese Yen", name_plural: "Japanese yen", symbol: "¥", symbol_native: "￥", decimal_digits: 0}

  """

  alias BeamLabCountries.Currency

  # Load currencies from JSON at compile time
  @currencies_path Path.join([:code.priv_dir(:beamlab_countries), "data", "currencies.json"])
  @external_resource @currencies_path

  @currencies @currencies_path
              |> File.read!()
              |> JSON.decode!()

  @doc """
  Returns a Currency struct for the given ISO 4217 currency code.

  ## Examples

      iex> currency = BeamLabCountries.Currencies.get("USD")
      iex> currency.name
      "US Dollar"
      iex> currency.symbol
      "$"

      iex> BeamLabCountries.Currencies.get("EUR")
      %BeamLabCountries.Currency{code: "EUR", name: "Euro", name_plural: "euros", symbol: "€", symbol_native: "€", decimal_digits: 2}

      iex> BeamLabCountries.Currencies.get("INVALID")
      nil

  """
  def get(code) when is_binary(code) do
    case Map.get(@currencies, String.upcase(code)) do
      nil ->
        nil

      data ->
        %Currency{
          code: data["code"],
          name: data["name"],
          name_plural: data["name_plural"],
          symbol: data["symbol"],
          symbol_native: data["symbol_native"],
          decimal_digits: data["decimal_digits"]
        }
    end
  end

  @doc """
  Returns a Currency struct for the given ISO 4217 currency code.

  Raises `ArgumentError` if the currency code is not found.

  ## Examples

      iex> BeamLabCountries.Currencies.get!("USD").name
      "US Dollar"

      iex> BeamLabCountries.Currencies.get!("INVALID")
      ** (ArgumentError) Unknown currency code: INVALID

  """
  def get!(code) when is_binary(code) do
    case get(code) do
      nil -> raise ArgumentError, "Unknown currency code: #{code}"
      currency -> currency
    end
  end

  @doc """
  Returns the currency name for the given code.

  ## Examples

      iex> BeamLabCountries.Currencies.name("USD")
      "US Dollar"

      iex> BeamLabCountries.Currencies.name("EUR")
      "Euro"

      iex> BeamLabCountries.Currencies.name("INVALID")
      nil

  """
  def name(code) when is_binary(code) do
    case Map.get(@currencies, String.upcase(code)) do
      nil -> nil
      data -> data["name"]
    end
  end

  @doc """
  Returns the currency symbol for the given code.

  ## Examples

      iex> BeamLabCountries.Currencies.symbol("USD")
      "$"

      iex> BeamLabCountries.Currencies.symbol("EUR")
      "€"

      iex> BeamLabCountries.Currencies.symbol("GBP")
      "£"

      iex> BeamLabCountries.Currencies.symbol("INVALID")
      nil

  """
  def symbol(code) when is_binary(code) do
    case Map.get(@currencies, String.upcase(code)) do
      nil -> nil
      data -> data["symbol"]
    end
  end

  @doc """
  Returns the native currency symbol for the given code.

  The native symbol is the symbol used in the currency's home country,
  which may differ from the international symbol.

  ## Examples

      iex> BeamLabCountries.Currencies.symbol_native("JPY")
      "￥"

      iex> BeamLabCountries.Currencies.symbol_native("RUB")
      "₽"

      iex> BeamLabCountries.Currencies.symbol_native("INVALID")
      nil

  """
  def symbol_native(code) when is_binary(code) do
    case Map.get(@currencies, String.upcase(code)) do
      nil -> nil
      data -> data["symbol_native"]
    end
  end

  @doc """
  Returns the number of decimal digits for the given currency.

  This is useful for formatting currency amounts correctly.
  Most currencies use 2 decimal places, but some (like JPY) use 0,
  and others (like BHD, KWD) use 3.

  ## Examples

      iex> BeamLabCountries.Currencies.decimal_digits("USD")
      2

      iex> BeamLabCountries.Currencies.decimal_digits("JPY")
      0

      iex> BeamLabCountries.Currencies.decimal_digits("KWD")
      3

      iex> BeamLabCountries.Currencies.decimal_digits("INVALID")
      nil

  """
  def decimal_digits(code) when is_binary(code) do
    case Map.get(@currencies, String.upcase(code)) do
      nil -> nil
      data -> data["decimal_digits"]
    end
  end

  @doc """
  Returns the Currency struct for a given country's alpha2 code.

  Uses the `currency_code` field from the country data.

  ## Examples

      iex> currency = BeamLabCountries.Currencies.for_country("US")
      iex> currency.code
      "USD"

      iex> currency = BeamLabCountries.Currencies.for_country("JP")
      iex> currency.code
      "JPY"

      iex> BeamLabCountries.Currencies.for_country("INVALID")
      nil

  """
  def for_country(country_code) when is_binary(country_code) do
    case BeamLabCountries.get(country_code) do
      nil -> nil
      country -> get(country.currency_code)
    end
  end

  @doc """
  Returns all currencies as a list of Currency structs, sorted by code.

  ## Examples

      iex> currencies = BeamLabCountries.Currencies.all()
      iex> length(currencies) > 100
      true
      iex> %BeamLabCountries.Currency{} = hd(currencies)

  """
  def all do
    @currencies
    |> Enum.map(fn {_code, data} ->
      %Currency{
        code: data["code"],
        name: data["name"],
        name_plural: data["name_plural"],
        symbol: data["symbol"],
        symbol_native: data["symbol_native"],
        decimal_digits: data["decimal_digits"]
      }
    end)
    |> Enum.sort_by(& &1.code)
  end

  @doc """
  Returns all currency codes as a list.

  ## Examples

      iex> codes = BeamLabCountries.Currencies.all_codes()
      iex> "USD" in codes
      true
      iex> "EUR" in codes
      true

  """
  def all_codes do
    Map.keys(@currencies) |> Enum.sort()
  end

  @doc """
  Returns the count of supported currencies.

  ## Examples

      iex> BeamLabCountries.Currencies.count()
      155

  """
  def count do
    map_size(@currencies)
  end

  @doc """
  Checks if a currency code is valid.

  ## Examples

      iex> BeamLabCountries.Currencies.valid?("USD")
      true

      iex> BeamLabCountries.Currencies.valid?("usd")
      true

      iex> BeamLabCountries.Currencies.valid?("INVALID")
      false

  """
  def valid?(code) when is_binary(code) do
    Map.has_key?(@currencies, String.upcase(code))
  end

  @doc """
  Returns all countries that use a given currency.

  ## Examples

      iex> countries = BeamLabCountries.Currencies.countries_for_currency("EUR")
      iex> length(countries) > 10
      true
      iex> "Germany" in Enum.map(countries, & &1.name)
      true

      iex> countries = BeamLabCountries.Currencies.countries_for_currency("USD")
      iex> "United States of America" in Enum.map(countries, & &1.name)
      true

  """
  def countries_for_currency(currency_code) when is_binary(currency_code) do
    code = String.upcase(currency_code)

    BeamLabCountries.all()
    |> Enum.filter(fn country ->
      country.currency_code == code
    end)
    |> Enum.sort_by(& &1.name)
  end

  @doc """
  Formats an amount with the currency symbol.

  Uses the currency's decimal_digits to format the number correctly.

  ## Options

    * `:native` - Use the native symbol instead of international symbol (default: false)
    * `:symbol_position` - Position of symbol, `:before` or `:after` (default: `:before`)

  ## Examples

      iex> BeamLabCountries.Currencies.format(1234.56, "USD")
      "$1,234.56"

      iex> BeamLabCountries.Currencies.format(1234, "JPY")
      "¥1,234"

      iex> BeamLabCountries.Currencies.format(1234.567, "KWD")
      "KD1,234.567"

      iex> BeamLabCountries.Currencies.format(1234.56, "EUR", symbol_position: :after)
      "1,234.56€"

      iex> BeamLabCountries.Currencies.format(1234.56, "RUB", native: true)
      "₽1,234.56"

  """
  def format(amount, currency_code, opts \\ []) when is_number(amount) and is_binary(currency_code) do
    case get(currency_code) do
      nil ->
        nil

      currency ->
        native = Keyword.get(opts, :native, false)
        position = Keyword.get(opts, :symbol_position, :before)

        symbol = if native, do: currency.symbol_native, else: currency.symbol
        formatted_number = format_number(amount, currency.decimal_digits)

        case position do
          :before -> "#{symbol}#{formatted_number}"
          :after -> "#{formatted_number}#{symbol}"
        end
    end
  end

  # Format a number with thousand separators and decimal places
  defp format_number(amount, decimal_digits) do
    rounded = Float.round(amount / 1, decimal_digits)

    {integer_part, decimal_part} =
      if decimal_digits == 0 do
        {trunc(rounded), ""}
      else
        integer = trunc(rounded)
        decimal = rounded - integer
        decimal_str = :erlang.float_to_binary(decimal, decimals: decimal_digits)
        # Remove "0." prefix
        decimal_str = String.slice(decimal_str, 2..-1//1)
        {integer, ".#{decimal_str}"}
      end

    formatted_integer =
      integer_part
      |> Integer.to_string()
      |> String.graphemes()
      |> Enum.reverse()
      |> Enum.chunk_every(3)
      |> Enum.join(",")
      |> String.reverse()

    "#{formatted_integer}#{decimal_part}"
  end
end
