defmodule BeamLabCountries.DataIntegrityTest do
  use ExUnit.Case, async: true

  alias BeamLabCountries.Subdivisions
  alias BeamLabCountries.Unions

  @subdivision_files Path.wildcard(Path.join(["priv", "data", "subdivisions", "*.yaml"]))

  describe "subdivisions" do
    test "data files are named after uppercase alpha2 codes of known countries" do
      for file <- @subdivision_files do
        code = Path.basename(file, ".yaml")
        assert code =~ ~r/\A[A-Z]{2}\z/, "bad file name: #{file}"
        assert BeamLabCountries.get(code), "no country for #{file}"
      end
    end

    test "every data file is reachable" do
      for file <- @subdivision_files do
        code = Path.basename(file, ".yaml")
        refute Subdivisions.all(code) == [], "#{code} has a data file but no subdivisions"
      end
    end

    test "Cayman Islands and Tajikistan have subdivisions" do
      assert length(Subdivisions.all("KY")) == 6
      assert %{id: "DU"} = Subdivisions.get("TJ", "DU")
      assert length(Subdivisions.all("TJ")) == 5
    end

    test "every subdivision has a name and a list of unofficial names" do
      for country <- BeamLabCountries.all(), sub <- Subdivisions.all(country) do
        assert is_binary(sub.name), "#{country.alpha2}/#{sub.id} has no name"
        assert is_list(sub.unofficial_names)
      end
    end

    test "falls back to the English translation when there is no dedicated name" do
      assert %{name: "Berat County"} = Subdivisions.get("AL", "01")
    end

    test "lookups are nil-safe" do
      assert Subdivisions.all(nil) == []
      assert Subdivisions.get(nil, "CA") == nil
      assert Subdivisions.get("US", nil) == nil
    end
  end

  describe "countries" do
    test "eu_member and eea_member are always booleans" do
      for country <- BeamLabCountries.all() do
        assert is_boolean(country.eu_member)
        assert is_boolean(country.eea_member)
      end

      assert length(BeamLabCountries.filter_by(:eu_member, false)) == 223
    end

    test "membership flags agree with the corresponding unions" do
      for country <- BeamLabCountries.all() do
        assert country.eu_member == Unions.member?(country.alpha2, "eu"), country.alpha2
        assert country.eea_member == Unions.member?(country.alpha2, "eea"), country.alpha2
      end
    end

    test "every euro area member uses EUR" do
      for country <- Unions.member_countries("eurozone") do
        assert country.currency_code == "EUR", country.alpha2
        assert BeamLabCountries.Currencies.for_country(country.alpha2).code == "EUR"
      end
    end

    test "Caribbean guilder resolves for Curacao and Sint Maarten" do
      for code <- ["CW", "SX"] do
        assert BeamLabCountries.get(code).currency_code == "XCG"
        assert BeamLabCountries.Currencies.for_country(code).code == "XCG"
      end

      assert BeamLabCountries.Currencies.for_country("AN").code == "ANG"
    end

    test "prefixes are never the literal string \"None\"" do
      for country <- BeamLabCountries.all() do
        refute country.national_prefix == "None"
        refute country.international_prefix == "None"
      end

      assert BeamLabCountries.get("TL").international_prefix == nil
    end

    test "every country has IANA time zones" do
      for country <- BeamLabCountries.all() do
        assert [_ | _] = country.timezones, "#{country.alpha2} has no time zones"

        for zone <- country.timezones do
          assert zone =~ ~r{\A[A-Za-z]+/[A-Za-z0-9_+\-/]+\z}, "bad zone #{zone}"
        end
      end

      assert BeamLabCountries.get("EE").timezones == ["Europe/Tallinn"]
      assert %{alpha2: "EE"} = BeamLabCountries.get_by(:timezones, "europe/tallinn")
    end

    test "Netherlands Antilles is complete" do
      an = BeamLabCountries.get("AN")
      assert an.languages_official == ["nl"]
      assert an.geo.latitude
      assert an.start_of_week == "monday"
      assert is_list(an.unofficial_names)
    end

    test "unknown attributes raise instead of silently matching nothing" do
      assert_raise ArgumentError, ~r/unknown country attribute: :regoin/, fn ->
        BeamLabCountries.filter_by(:regoin, "Europe")
      end

      assert_raise ArgumentError, fn -> BeamLabCountries.filter_by(region: "Europe", nope: 1) end
      assert_raise ArgumentError, fn -> BeamLabCountries.get_by(:nope, 1) end
      assert_raise ArgumentError, fn -> BeamLabCountries.exists?(:nope, 1) end
    end

    test "lookups are nil-safe" do
      assert BeamLabCountries.get(nil) == nil
      assert BeamLabCountries.get(:pl) == nil
      assert BeamLabCountries.get_by_alpha3(nil) == nil

      assert_raise ArgumentError, fn -> BeamLabCountries.get!(nil) end
    end
  end

  describe "unions" do
    test "all member codes are known countries without duplicates" do
      for union <- Unions.all() do
        assert Enum.all?(union.members, &BeamLabCountries.get/1), "#{union.code}: unknown member"
        assert union.members == Enum.uniq(union.members), "#{union.code}: duplicate member"
      end
    end

    test "membership reflects recent changes" do
      assert Unions.member?("TL", "asean")
      refute Unions.member?("AO", "opec")
      refute Unions.member?("AE", "opec")
      refute Unions.member?("CH", "eea")
      assert length(Unions.get("eea").members) == 30
      assert Unions.member?("EH", "african_union")
      assert Unions.member?("BO", "mercosur")
    end

    test "new unions are available" do
      for code <- ~w(brics cis oic pacific_alliance commonwealth arab_league gcc schengen
                     eurozone sco caricom ecowas sadc eac council_of_europe cptpp) do
        assert Unions.exists?(code), "missing #{code}"
      end

      assert Unions.member?("BG", "eurozone")
      assert Unions.member?("RU", "brics")
      refute Unions.member?("RU", "council_of_europe")
    end

    test "lookups are nil-safe" do
      assert Unions.get(nil) == nil
      assert Unions.for_country(nil) == []
      assert Unions.codes_for_country(nil) == []
      refute Unions.member?(nil, "eu")
      assert Unions.member_countries(nil) == []
    end
  end

  describe "currencies and languages" do
    test "lookups are nil-safe" do
      alias BeamLabCountries.{Currencies, Languages}

      assert Currencies.get(nil) == nil
      assert Currencies.symbol(nil) == nil
      refute Currencies.valid?(nil)
      assert Currencies.for_country(nil) == nil
      assert Currencies.format(1, nil) == nil
      assert Languages.get(nil) == nil
      assert Languages.get_name(nil) == nil
      refute Languages.valid?(nil)
      assert Languages.get_locale(nil) == nil
      assert Languages.countries_for_language(nil) == []
    end

    test "format/3 places the sign in front and drops it for zero" do
      alias BeamLabCountries.Currencies

      assert Currencies.format(-1234.56, "USD") == "-$1,234.56"
      assert Currencies.format(-1234, "JPY") == "-¥1,234"
      assert Currencies.format(-1234.567, "KWD", symbol_position: :after) == "-1,234.567KD"
      assert Currencies.format(-0.004, "USD") == "$0.00"
      assert Currencies.format(0, "USD") == "$0.00"

      assert_raise ArgumentError, fn -> Currencies.format(1, "USD", symbol_position: :middle) end
    end
  end
end
