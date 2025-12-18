defmodule BeamLabCountries.CurrenciesTest do
  use ExUnit.Case, async: true
  doctest BeamLabCountries.Currencies

  alias BeamLabCountries.Currencies
  alias BeamLabCountries.Currency

  describe "get/1" do
    test "returns Currency struct for valid code" do
      currency = Currencies.get("USD")
      assert %Currency{} = currency
      assert currency.code == "USD"
      assert currency.name == "US Dollar"
      assert currency.name_plural == "US dollars"
      assert currency.symbol == "$"
      assert currency.symbol_native == "$"
      assert currency.decimal_digits == 2
    end

    test "returns Currency for various currencies" do
      eur = Currencies.get("EUR")
      assert eur.name == "Euro"
      assert eur.symbol == "€"
      assert eur.decimal_digits == 2

      jpy = Currencies.get("JPY")
      assert jpy.name == "Japanese Yen"
      assert jpy.symbol == "¥"
      assert jpy.decimal_digits == 0

      gbp = Currencies.get("GBP")
      assert gbp.name == "British Pound"
      assert gbp.symbol == "£"
    end

    test "is case insensitive" do
      assert Currencies.get("usd") == Currencies.get("USD")
      assert Currencies.get("Eur") == Currencies.get("EUR")
    end

    test "returns nil for invalid code" do
      assert Currencies.get("INVALID") == nil
      assert Currencies.get("XXX") == nil
    end
  end

  describe "get!/1" do
    test "returns Currency struct for valid code" do
      currency = Currencies.get!("USD")
      assert currency.code == "USD"
    end

    test "raises ArgumentError for invalid code" do
      assert_raise ArgumentError, "Unknown currency code: INVALID", fn ->
        Currencies.get!("INVALID")
      end
    end
  end

  describe "name/1" do
    test "returns name for valid code" do
      assert Currencies.name("USD") == "US Dollar"
      assert Currencies.name("EUR") == "Euro"
      assert Currencies.name("JPY") == "Japanese Yen"
    end

    test "is case insensitive" do
      assert Currencies.name("usd") == "US Dollar"
    end

    test "returns nil for invalid code" do
      assert Currencies.name("INVALID") == nil
    end
  end

  describe "symbol/1" do
    test "returns symbol for valid code" do
      assert Currencies.symbol("USD") == "$"
      assert Currencies.symbol("EUR") == "€"
      assert Currencies.symbol("GBP") == "£"
      assert Currencies.symbol("JPY") == "¥"
    end

    test "is case insensitive" do
      assert Currencies.symbol("usd") == "$"
    end

    test "returns nil for invalid code" do
      assert Currencies.symbol("INVALID") == nil
    end
  end

  describe "symbol_native/1" do
    test "returns native symbol for valid code" do
      assert Currencies.symbol_native("USD") == "$"
      assert Currencies.symbol_native("RUB") == "₽"
      assert Currencies.symbol_native("JPY") == "￥"
    end

    test "returns nil for invalid code" do
      assert Currencies.symbol_native("INVALID") == nil
    end
  end

  describe "decimal_digits/1" do
    test "returns decimal digits for valid code" do
      # Most currencies have 2 decimal places
      assert Currencies.decimal_digits("USD") == 2
      assert Currencies.decimal_digits("EUR") == 2

      # Some currencies have 0 decimal places
      assert Currencies.decimal_digits("JPY") == 0
      assert Currencies.decimal_digits("KRW") == 0

      # Some currencies have 3 decimal places
      assert Currencies.decimal_digits("KWD") == 3
      assert Currencies.decimal_digits("BHD") == 3
    end

    test "returns nil for invalid code" do
      assert Currencies.decimal_digits("INVALID") == nil
    end
  end

  describe "for_country/1" do
    test "returns currency for country" do
      usd = Currencies.for_country("US")
      assert usd.code == "USD"

      jpy = Currencies.for_country("JP")
      assert jpy.code == "JPY"

      gbp = Currencies.for_country("GB")
      assert gbp.code == "GBP"
    end

    test "returns nil for invalid country" do
      assert Currencies.for_country("INVALID") == nil
    end
  end

  describe "all/0" do
    test "returns all currencies as Currency structs" do
      currencies = Currencies.all()
      assert length(currencies) > 100
      assert Enum.all?(currencies, &match?(%Currency{}, &1))
    end

    test "currencies are sorted by code" do
      currencies = Currencies.all()
      codes = Enum.map(currencies, & &1.code)
      assert codes == Enum.sort(codes)
    end
  end

  describe "all_codes/0" do
    test "returns all currency codes" do
      codes = Currencies.all_codes()
      assert "USD" in codes
      assert "EUR" in codes
      assert "JPY" in codes
      assert "GBP" in codes
    end

    test "codes are sorted" do
      codes = Currencies.all_codes()
      assert codes == Enum.sort(codes)
    end
  end

  describe "count/0" do
    test "returns count of currencies" do
      assert Currencies.count() == 155
    end
  end

  describe "valid?/1" do
    test "returns true for valid codes" do
      assert Currencies.valid?("USD")
      assert Currencies.valid?("EUR")
      assert Currencies.valid?("JPY")
    end

    test "returns false for invalid codes" do
      refute Currencies.valid?("INVALID")
      refute Currencies.valid?("XXX")
    end

    test "is case insensitive" do
      assert Currencies.valid?("usd")
      assert Currencies.valid?("Eur")
    end
  end

  describe "countries_for_currency/1" do
    test "returns countries using EUR" do
      countries = Currencies.countries_for_currency("EUR")
      country_names = Enum.map(countries, & &1.name)

      assert "Germany" in country_names
      assert "France" in country_names
      assert "Italy" in country_names
      assert "Spain" in country_names
      # Many countries use EUR
      assert length(countries) > 10
    end

    test "returns countries using USD" do
      countries = Currencies.countries_for_currency("USD")
      country_names = Enum.map(countries, & &1.name)

      assert "United States of America" in country_names
    end

    test "is case insensitive" do
      countries_lower = Currencies.countries_for_currency("eur")
      countries_upper = Currencies.countries_for_currency("EUR")
      assert length(countries_lower) == length(countries_upper)
    end

    test "countries are sorted by name" do
      countries = Currencies.countries_for_currency("EUR")
      names = Enum.map(countries, & &1.name)
      assert names == Enum.sort(names)
    end
  end

  describe "format/3" do
    test "formats amount with currency symbol" do
      assert Currencies.format(1234.56, "USD") == "$1,234.56"
      assert Currencies.format(1234, "JPY") == "¥1,234"
      assert Currencies.format(1234.567, "KWD") == "KD1,234.567"
    end

    test "formats with symbol after amount" do
      assert Currencies.format(1234.56, "EUR", symbol_position: :after) == "1,234.56€"
    end

    test "formats with native symbol" do
      assert Currencies.format(1234.56, "RUB", native: true) == "₽1,234.56"
    end

    test "returns nil for invalid currency" do
      assert Currencies.format(100, "INVALID") == nil
    end

    test "handles zero amount" do
      assert Currencies.format(0, "USD") == "$0.00"
      assert Currencies.format(0, "JPY") == "¥0"
    end

    test "handles large amounts" do
      assert Currencies.format(1_000_000.00, "USD") == "$1,000,000.00"
    end
  end
end
