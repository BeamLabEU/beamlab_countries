defmodule BeamLabCountriesTest do
  use ExUnit.Case, async: true
  doctest BeamLabCountries

  describe "all/0" do
    test "get all countries" do
      countries = BeamLabCountries.all()
      assert Enum.count(countries) == 250
    end
  end

  describe "get/1" do
    test "gets one country" do
      %{alpha2: "GB"} = BeamLabCountries.get("GB")
    end
  end

  describe "exists?/2" do
    test "checks if country exists" do
      assert BeamLabCountries.exists?(:name, "Poland")
      refute BeamLabCountries.exists?(:name, "Polande")
    end
  end

  describe "filter_by/2" do
    test "return empty list when there are no results" do
      countries = BeamLabCountries.filter_by(:region, "Azeroth")
      assert countries == []
    end

    test "filters countries by alpha2" do
      [%{alpha3: "DEU"}] = BeamLabCountries.filter_by(:alpha2, "DE")
      [%{alpha3: "SMR"}] = BeamLabCountries.filter_by(:alpha2, "sm")
    end

    test "filters countries by alpha3" do
      [%{alpha2: "VC"}] = BeamLabCountries.filter_by(:alpha3, "VCT")
      [%{alpha2: "HU"}] = BeamLabCountries.filter_by(:alpha3, "hun")
    end

    test "filters countries by name" do
      [%{alpha2: "AW"}] = BeamLabCountries.filter_by(:name, "Aruba")
      [%{alpha2: "EE"}] = BeamLabCountries.filter_by(:name, "estonia")
    end

    test "filter countries by unofficial names" do
      [%{alpha2: "GB"}] = BeamLabCountries.filter_by(:unofficial_names, "Reino Unido")
      [%{alpha2: "GB"}] = BeamLabCountries.filter_by(:unofficial_names, "The United Kingdom")
      [%{alpha2: "US"}] = BeamLabCountries.filter_by(:unofficial_names, "États-Unis")
      [%{alpha2: "US"}] = BeamLabCountries.filter_by(:unofficial_names, "アメリカ合衆国")
      [%{alpha2: "RU"}] = BeamLabCountries.filter_by(:unofficial_names, "Россия")
      [%{alpha2: "LB"}] = BeamLabCountries.filter_by(:unofficial_names, "لبنان")
    end

    test "filters countries with basic string sanitization" do
      [%{alpha2: "PR"}] = BeamLabCountries.filter_by(:name, "\npuerto    rico \n   ")

      countries = BeamLabCountries.filter_by(:subregion, "WESTERNEUROPE")
      assert Enum.count(countries) == 9
    end

    test "filters many countries by region" do
      countries = BeamLabCountries.filter_by(:region, "Europe")
      assert Enum.count(countries) == 51
    end

    test "filters by official language" do
      countries = BeamLabCountries.filter_by(:languages_official, "en")
      assert Enum.count(countries) == 92
    end

    test "filters by integer attributes" do
      countries = BeamLabCountries.filter_by(:national_number_lengths, 10)
      assert Enum.count(countries) == 59

      countries = BeamLabCountries.filter_by(:national_destination_code_lengths, "2")
      assert Enum.count(countries) == 200
    end

    test "filters by multiple attributes" do
      countries = BeamLabCountries.filter_by(region: "Europe", eu_member: true)
      assert length(countries) == 26
      assert Enum.all?(countries, & &1.eu_member)
      assert Enum.all?(countries, &(&1.region == "Europe"))
    end

    test "filters by multiple attributes with no results" do
      countries = BeamLabCountries.filter_by(region: "Africa", eu_member: true)
      assert countries == []
    end
  end

  describe "short_name" do
    test "all countries have a short_name" do
      assert Enum.all?(BeamLabCountries.all(), &(not is_nil(&1.short_name)))
    end

    test "returns common short name for countries with long official names" do
      assert BeamLabCountries.get("US").short_name == "United States"
      assert BeamLabCountries.get("GB").short_name == "United Kingdom"
      assert BeamLabCountries.get("KR").short_name == "South Korea"
      assert BeamLabCountries.get("RU").short_name == "Russia"
      assert BeamLabCountries.get("TW").short_name == "Taiwan"
      assert BeamLabCountries.get("IR").short_name == "Iran"
      assert BeamLabCountries.get("VN").short_name == "Vietnam"
    end

    test "short_name equals name for countries without a common alternative" do
      assert BeamLabCountries.get("DE").short_name == "Germany"
      assert BeamLabCountries.get("FR").short_name == "France"
      assert BeamLabCountries.get("JP").short_name == "Japan"
    end

    test "can look up country by short_name" do
      %{alpha2: "RU"} = BeamLabCountries.get_by(:short_name, "Russia")
    end

    test "can filter by short_name" do
      [%{alpha2: "KR"}] = BeamLabCountries.filter_by(:short_name, "South Korea")
    end
  end

  describe "phone_prefix" do
    test "formats country_code with + prefix" do
      assert BeamLabCountries.get("EE").phone_prefix == "+372"
      assert BeamLabCountries.get("US").phone_prefix == "+1"
      assert BeamLabCountries.get("GB").phone_prefix == "+44"
      assert BeamLabCountries.get("PL").phone_prefix == "+48"
    end

    test "is nil when country has no country_code" do
      no_code =
        BeamLabCountries.all()
        |> Enum.filter(&is_nil(&1.country_code))

      assert Enum.all?(no_code, &is_nil(&1.phone_prefix))
    end

    test "can look up country by phone_prefix" do
      %{alpha2: "EE"} = BeamLabCountries.get_by(:phone_prefix, "+372")
    end
  end

  describe "eu_members/0" do
    test "returns 27 EU member countries" do
      eu = BeamLabCountries.eu_members()
      assert length(eu) == 27
    end

    test "all are EU members" do
      eu = BeamLabCountries.eu_members()
      assert Enum.all?(eu, & &1.eu_member)
    end

    test "includes known EU members" do
      eu_alpha2 = BeamLabCountries.eu_members() |> Enum.map(& &1.alpha2) |> MapSet.new()
      assert "DE" in eu_alpha2
      assert "FR" in eu_alpha2
      assert "PL" in eu_alpha2
    end

    test "excludes non-EU countries" do
      eu_alpha2 = BeamLabCountries.eu_members() |> Enum.map(& &1.alpha2) |> MapSet.new()
      refute "US" in eu_alpha2
      refute "GB" in eu_alpha2
      refute "CH" in eu_alpha2
    end
  end

  test "get country subdivisions" do
    country = List.first(BeamLabCountries.filter_by(:alpha2, "BR"))
    assert Enum.count(BeamLabCountries.Subdivisions.all(country)) == 27

    country = List.first(BeamLabCountries.filter_by(:alpha2, "AD"))
    assert Enum.count(BeamLabCountries.Subdivisions.all(country)) == 7

    country = List.first(BeamLabCountries.filter_by(:alpha2, "AI"))
    assert Enum.count(BeamLabCountries.Subdivisions.all(country)) == 14
  end

  describe "language_locales" do
    test "is populated for countries with multi-variant languages" do
      # UK uses British English
      country = BeamLabCountries.get("GB")
      assert %{en: "en-GB"} = country.language_locales

      # US uses American English
      country = BeamLabCountries.get("US")
      assert %{en: "en-US"} = country.language_locales

      # Canada has both English and French variants
      country = BeamLabCountries.get("CA")
      assert %{en: "en-CA", fr: "fr-CA"} = country.language_locales
    end

    test "all language_locales map to valid locales" do
      invalid_mappings =
        BeamLabCountries.all()
        |> Enum.reject(&is_nil(&1.language_locales))
        |> Enum.flat_map(fn country ->
          country.language_locales
          |> Map.values()
          |> Enum.reject(&BeamLabCountries.Languages.valid_locale?/1)
          |> Enum.map(&{country.alpha2, &1})
        end)

      assert invalid_mappings == [],
             "Found invalid locale mappings: #{inspect(invalid_mappings)}"
    end

    test "is nil for countries without spoken languages" do
      # Only countries with no spoken languages have nil language_locales
      # Antarctica
      country = BeamLabCountries.get("AQ")
      assert is_nil(country.language_locales)

      # Bouvet Island
      country = BeamLabCountries.get("BV")
      assert is_nil(country.language_locales)
    end

    test "includes single-variant locale mappings" do
      # Afghanistan speaks ps, uz, tk - all single-variant
      af = BeamLabCountries.get("AF")
      assert af.language_locales[:ps] == "ps"
      assert af.language_locales[:uz] == "uz"
      assert af.language_locales[:tk] == "tk"

      # Mongolia speaks mn - single-variant
      mn = BeamLabCountries.get("MN")
      assert mn.language_locales[:mn] == "mn"
    end

    test "maps languages spoken to appropriate regional variants" do
      # Kenya was a British colony, uses British English
      ke = BeamLabCountries.get("KE")
      assert ke.language_locales[:en] == "en-GB"

      # Jamaica is in the Americas, uses American English
      jm = BeamLabCountries.get("JM")
      assert jm.language_locales[:en] == "en-US"

      # Luxembourg maps multiple languages
      lu = BeamLabCountries.get("LU")
      assert lu.language_locales[:de] == "de-DE"
      assert lu.language_locales[:fr] == "fr-FR"
      assert lu.language_locales[:en] == "en-GB"
      assert lu.language_locales[:pt] == "pt-PT"

      # Brazil uses Brazilian Portuguese
      br = BeamLabCountries.get("BR")
      assert br.language_locales[:pt] == "pt-BR"

      # Portugal uses European Portuguese
      pt = BeamLabCountries.get("PT")
      assert pt.language_locales[:pt] == "pt-PT"
    end
  end

  describe "vat_rates" do
    test "returns proper numeric values for standard rate" do
      # Estonia has 24% VAT (updated 2025)
      %{vat_rates: %{standard: standard}} = BeamLabCountries.get("EE")
      assert is_integer(standard)
      assert standard == 24

      # Germany has 19% VAT
      %{vat_rates: %{standard: de_standard}} = BeamLabCountries.get("DE")
      assert is_integer(de_standard)
      assert de_standard == 19
    end

    test "returns proper numeric values for reduced rates" do
      # Estonia has reduced rate of 9%
      %{vat_rates: %{reduced: reduced}} = BeamLabCountries.get("EE")
      assert is_list(reduced)
      assert Enum.all?(reduced, &is_number/1)
      assert 9 in reduced

      # Germany has reduced rate of 7%
      %{vat_rates: %{reduced: de_reduced}} = BeamLabCountries.get("DE")
      assert is_list(de_reduced)
      assert Enum.all?(de_reduced, &is_number/1)
      assert 7 in de_reduced

      # France has multiple reduced rates
      %{vat_rates: %{reduced: fr_reduced}} = BeamLabCountries.get("FR")
      assert is_list(fr_reduced)
      assert Enum.all?(fr_reduced, &is_number/1)
      assert length(fr_reduced) >= 2
    end

    test "returns nil for countries without VAT" do
      %{vat_rates: vat_rates} = BeamLabCountries.get("US")
      assert is_nil(vat_rates)
    end

    test "handles super_reduced and parking rates" do
      # France has super_reduced rate
      %{vat_rates: %{super_reduced: super_reduced}} = BeamLabCountries.get("FR")
      assert is_number(super_reduced) or is_nil(super_reduced)
    end
  end
end
