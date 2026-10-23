defmodule BeamLabCountries.FormatsTest do
  use ExUnit.Case, async: true

  alias BeamLabCountries.Formats

  doctest BeamLabCountries.Formats

  describe "format_number/3" do
    test "accepts a country struct or a case-insensitive code" do
      assert Formats.format_number(BeamLabCountries.get("DE"), 1234.5) == "1.234,50"
      assert Formats.format_number("de", 1234.5) == "1.234,50"
    end

    test "groups by thousands" do
      assert Formats.format_number("GB", 0) == "0"
      assert Formats.format_number("GB", 999) == "999"
      assert Formats.format_number("GB", 1000) == "1,000"
      assert Formats.format_number("GB", 100_000) == "100,000"
      assert Formats.format_number("GB", 1_234_567_890) == "1,234,567,890"
    end

    test ":decimals pads integers and rounds floats" do
      assert Formats.format_number("DE", 5, decimals: 2) == "5,00"
      assert Formats.format_number("DE", 1.005, decimals: 0) == "1"
      assert Formats.format_number("DE", 2.5, decimals: 3) == "2,500"
    end

    test "drops the sign of a negative number that rounds to zero" do
      assert Formats.format_number("GB", -0.001) == "0.00"
      assert Formats.format_number("GB", -1234.5) == "-1,234.50"
    end

    test "returns nil for unknown or non-string countries" do
      assert Formats.format_number("XX", 1) == nil
      assert Formats.format_number(nil, 1) == nil
    end

    test "rejects invalid :decimals" do
      for amount <- [1, 1.0], decimals <- [-1, 1.5, 16, nil, "2"] do
        assert_raise ArgumentError, ~r/:decimals.*0\.\.15/, fn ->
          Formats.format_number("DE", amount, decimals: decimals)
        end
      end
    end

    test "accepts the maximum precision for integers and floats" do
      assert Formats.format_number("DE", 1, decimals: 15) == "1,000000000000000"
      assert Formats.format_number("DE", 1.25, decimals: 15) == "1,250000000000000"
    end

    test "keeps large integer inputs exact" do
      assert Formats.format_number("US", 123_456_789_012_345_678_901, decimals: 2) ==
               "123,456,789,012,345,678,901.00"
    end

    test "formats very large floats without the VM fixed-output size limit" do
      amount = Float.max_finite()
      expected = Formats.format_number("US", trunc(amount), decimals: 2)

      assert Formats.format_number("US", amount) == expected
      assert Formats.format_number("US", -amount) == "-" <> expected
    end

    test "every country formats a number with its own separators" do
      for c <- BeamLabCountries.all() do
        assert Formats.format_number(c, 1_234_567.5) ==
                 "1#{c.thousands_separator}234#{c.thousands_separator}567#{c.decimal_separator}50",
               c.alpha2
      end
    end
  end

  describe "format_date/2" do
    test "does not pad where the pattern does not" do
      assert Formats.format_date("US", ~D[2026-12-25]) == "12/25/2026"
      assert Formats.format_date("US", ~D[2026-01-02]) == "1/2/2026"
      assert Formats.format_date("TH", ~D[2026-01-02]) == "2/1/2026"
    end

    test "pads short years to four digits" do
      assert Formats.format_date("DE", ~D[0099-01-02]) == "02.01.0099"
      assert Formats.format_date("DE", ~D[0000-01-02]) == "02.01.0000"
      assert Formats.format_date("DE", ~D[-0001-01-02]) == "02.01.-0001"
    end

    test "works with DateTime and plain maps" do
      assert Formats.format_date("GB", ~U[2026-03-07 10:00:00Z]) == "07/03/2026"
      assert Formats.format_date("GB", %{year: 2026, month: 3, day: 7}) == "07/03/2026"
    end

    test "keeps literal text in the pattern" do
      assert Formats.format_date("BG", ~D[2026-03-07]) == "7.03.2026\u202Fг."
    end

    test "returns nil for unknown or non-string countries" do
      assert Formats.format_date("XX", ~D[2026-03-07]) == nil
      assert Formats.format_date(nil, ~D[2026-03-07]) == nil
    end

    test "every country produces a date without leftover tokens" do
      for c <- BeamLabCountries.all() do
        formatted = Formats.format_date(c, ~D[2026-03-07])
        assert formatted =~ "2026", c.alpha2
        refute formatted =~ ~r/[YMD]/u, "#{c.alpha2}: #{formatted}"
      end
    end
  end

  describe "format_currency/3" do
    test "uses the country's currency by default" do
      assert Formats.format_currency("EE", 1234.5) == "1 234,50 €"
      assert Formats.format_currency("US", 1234.5) == "$1,234.50"
    end

    test "uses the currency's decimal digits" do
      assert Formats.format_currency("JP", 1234.4) == "¥1,234"
      assert Formats.format_currency("DE", 3, currency: "JPY") == "3 ¥"
    end

    test ":native selects the native symbol" do
      assert Formats.format_currency("JP", 1, native: true) == "￥1"
    end

    test "returns nil for unknown country or currency" do
      assert Formats.format_currency("XX", 1) == nil
      assert Formats.format_currency("DE", 1, currency: "NOPE") == nil
      assert Formats.format_currency(nil, 1) == nil
      assert Formats.format_currency("DE", 1, currency: nil) == nil
    end

    test "formats very large floats through the shared currency helper" do
      amount = Float.max_finite()
      expected = Formats.format_number("US", trunc(amount), decimals: 2)

      assert Formats.format_currency("US", amount) == "$" <> expected
      assert BeamLabCountries.Currencies.format(-amount, "USD") == "-$" <> expected
    end

    test "places the sign before the pattern and drops it when rounding to zero" do
      assert Formats.format_currency("DE", -1234.56) == "-1.234,56\u00A0€"
      assert Formats.format_currency("US", -0.001) == "$0.00"
      assert Formats.format_currency("US", -0.5) == "-$0.50"
      assert Formats.format_currency("JP", -0.4) == "¥0"
    end

    test "returns nil when the country has no currency" do
      country = %{BeamLabCountries.get("DE") | currency_code: nil}
      assert Formats.format_currency(country, 1) == nil
      assert Formats.format_currency(country, 1, currency: "EUR") == "1,00\u00A0€"
    end
  end

  describe "Decimal amounts" do
    test "format_number/3 is exact" do
      assert Formats.format_number("DE", Decimal.new("30921.85")) == "30.921,85"

      assert Formats.format_number("US", Decimal.new("12345678901234567890.125"), decimals: 3) ==
               "12,345,678,901,234,567,890.125"
    end

    test "default decimals are the ones the Decimal already has" do
      assert Formats.format_number("GB", Decimal.new("5")) == "5"
      assert Formats.format_number("GB", Decimal.new("1.50")) == "1.50"
      assert Formats.format_number("GB", Decimal.new("1E+3")) == "1,000"
      assert Formats.format_number("GB", Decimal.new("0.000125")) == "0.000125"
    end

    test "rounds half away from zero, unlike the nearest float" do
      assert Formats.format_number("GB", Decimal.new("2.675"), decimals: 2) == "2.68"
      assert Formats.format_number("GB", 2.675, decimals: 2) == "2.67"
      assert Formats.format_number("GB", Decimal.new("-2.675"), decimals: 2) == "-2.68"
      assert Formats.format_number("GB", Decimal.new("0.5"), decimals: 0) == "1"
      assert Formats.format_number("GB", Decimal.new("0.4999"), decimals: 0) == "0"
      assert Formats.format_number("GB", Decimal.new("999.995"), decimals: 2) == "1,000.00"
    end

    test "pads with zeros and keeps leading zeros of the fraction" do
      assert Formats.format_number("GB", Decimal.new("3"), decimals: 2) == "3.00"
      assert Formats.format_number("GB", Decimal.new("0.05"), decimals: 2) == "0.05"
      assert Formats.format_number("GB", Decimal.new("0.001"), decimals: 2) == "0.00"
    end

    test "drops the sign of a negative that rounds to zero" do
      assert Formats.format_number("GB", Decimal.new("-0.004"), decimals: 2) == "0.00"
      assert Formats.format_number("GB", Decimal.new("-0"), decimals: 0) == "0"
      assert Formats.format_number("GB", Decimal.new("-0.005"), decimals: 2) == "-0.01"
    end

    test "NaN and infinity raise" do
      for value <- ["NaN", "Infinity", "-Infinity"] do
        assert_raise ArgumentError, ~r/NaN and infinity/, fn ->
          Formats.format_number("GB", Decimal.new(value))
        end
      end
    end

    test "format_currency/3 rounds to the currency's decimal places" do
      assert Formats.format_currency("DE", Decimal.new("30921.855")) == "30.921,86\u00A0€"
      assert Formats.format_currency("DE", Decimal.new("30921.85")) == "30.921,85\u00A0€"
      assert Formats.format_currency("GB", Decimal.new("-1234.5")) == "-£1,234.50"
      assert Formats.format_currency("JP", Decimal.new("1234.5")) == "¥1,235"
      assert Formats.format_currency("DE", Decimal.new("3"), currency: "JPY") == "3\u00A0¥"
      assert Formats.format_currency("US", Decimal.new("-0.001")) == "$0.00"
    end

    test "an invoice total survives where the float does not" do
      # 1.005 is stored as 1.00499999999999989...
      assert Formats.format_currency("US", 1.005) == "$1.00"
      assert Formats.format_currency("US", Decimal.new("1.005")) == "$1.01"
    end

    test "accepts any map shaped like a Decimal, so Decimal 2.x and 3.x both work" do
      assert Formats.format_number("DE", %{__struct__: Decimal, sign: 1, coef: 3_092_185, exp: -2}) ==
               "30.921,85"
    end

    test "unknown country is still nil" do
      assert Formats.format_number("XX", Decimal.new("1")) == nil
      assert Formats.format_currency("XX", Decimal.new("1")) == nil
    end

    test "other terms are still rejected" do
      assert_raise FunctionClauseError, fn -> Formats.format_number("DE", "30921.85") end
      assert_raise FunctionClauseError, fn -> Formats.format_currency("DE", "30921.85") end
    end
  end
end
