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
  end

  test "get country subdivisions" do
    country = List.first(BeamLabCountries.filter_by(:alpha2, "BR"))
    assert Enum.count(BeamLabCountries.Subdivisions.all(country)) == 27

    country = List.first(BeamLabCountries.filter_by(:alpha2, "AD"))
    assert Enum.count(BeamLabCountries.Subdivisions.all(country)) == 7

    country = List.first(BeamLabCountries.filter_by(:alpha2, "AI"))
    assert Enum.count(BeamLabCountries.Subdivisions.all(country)) == 14
  end

  describe "vat_rates" do
    test "returns proper numeric values for standard rate" do
      # Estonia has 20% VAT
      %{vat_rates: %{standard: standard}} = BeamLabCountries.get("EE")
      assert is_integer(standard)
      assert standard == 20

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
