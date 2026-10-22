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
      assert_raise ArgumentError, ~r/:decimals/, fn ->
        Formats.format_number("DE", 1, decimals: -1)
      end

      assert_raise ArgumentError, ~r/:decimals/, fn ->
        Formats.format_number("DE", 1, decimals: 1.5)
      end
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
    end

    test "works with DateTime and plain maps" do
      assert Formats.format_date("GB", ~U[2026-03-07 10:00:00Z]) == "07/03/2026"
      assert Formats.format_date("GB", %{year: 2026, month: 3, day: 7}) == "07/03/2026"
    end

    test "keeps literal text in the pattern" do
      assert Formats.format_date("BG", ~D[2026-03-07]) == "7.03.2026\u202Fг."
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
    end

    test "returns nil when the country has no currency" do
      assert BeamLabCountries.all()
             |> Enum.filter(&is_nil(&1.currency_code))
             |> Enum.all?(&is_nil(Formats.format_currency(&1, 1)))
    end
  end
end
