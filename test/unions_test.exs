defmodule BeamLabCountries.UnionsTest do
  use ExUnit.Case, async: true
  doctest BeamLabCountries.Unions

  describe "all/0" do
    test "returns all unions" do
      unions = BeamLabCountries.Unions.all()
      assert length(unions) == 29
      assert is_list(unions)
    end

    test "each union has required fields" do
      for union <- BeamLabCountries.Unions.all() do
        assert union.code
        assert union.name
        assert is_list(union.members)
      end
    end
  end

  describe "count/0" do
    test "returns correct count" do
      count = BeamLabCountries.Unions.count()
      assert count == length(BeamLabCountries.Unions.all())
    end
  end

  describe "get/1" do
    test "returns union by code" do
      union = BeamLabCountries.Unions.get("eu")
      assert union.name == "European Union"
      assert "DE" in union.members
    end

    test "is case insensitive" do
      assert BeamLabCountries.Unions.get("EU") == BeamLabCountries.Unions.get("eu")
    end

    test "returns nil for invalid code" do
      assert BeamLabCountries.Unions.get("invalid") == nil
    end
  end

  describe "get!/1" do
    test "returns union by code" do
      union = BeamLabCountries.Unions.get!("eu")
      assert union.name == "European Union"
    end

    test "raises for invalid code" do
      assert_raise ArgumentError, fn ->
        BeamLabCountries.Unions.get!("invalid")
      end
    end
  end

  describe "for_country/1" do
    test "returns unions for a member country" do
      unions = BeamLabCountries.Unions.for_country("DE")
      codes = Enum.map(unions, & &1.code)
      assert "eu" in codes
      assert "eea" in codes
      assert "nato" in codes
    end

    test "returns empty list for country with no unions" do
      unions = BeamLabCountries.Unions.for_country("XX")
      assert unions == []
    end

    test "is case insensitive" do
      assert BeamLabCountries.Unions.for_country("de") ==
               BeamLabCountries.Unions.for_country("DE")
    end
  end

  describe "codes_for_country/1" do
    test "returns union codes for a member country" do
      codes = BeamLabCountries.Unions.codes_for_country("US")
      assert "nato" in codes
      assert "g7" in codes
      assert "g20" in codes
      assert "usmca" in codes
    end

    test "returns empty list for country with no unions" do
      assert BeamLabCountries.Unions.codes_for_country("XX") == []
    end
  end

  describe "member?/2" do
    test "returns true for member country" do
      assert BeamLabCountries.Unions.member?("DE", "eu")
      assert BeamLabCountries.Unions.member?("FR", "nato")
      assert BeamLabCountries.Unions.member?("JP", "g7")
    end

    test "returns false for non-member country" do
      refute BeamLabCountries.Unions.member?("US", "eu")
      refute BeamLabCountries.Unions.member?("RU", "nato")
    end

    test "returns false for invalid union" do
      refute BeamLabCountries.Unions.member?("DE", "invalid")
    end

    test "is case insensitive" do
      assert BeamLabCountries.Unions.member?("de", "EU")
    end
  end

  describe "member_countries/1" do
    test "returns Country structs for members" do
      countries = BeamLabCountries.Unions.member_countries("eu")
      assert length(countries) == 27
      assert Enum.all?(countries, &match?(%BeamLabCountries.Country{}, &1))
    end

    test "returns correct count for g7" do
      countries = BeamLabCountries.Unions.member_countries("g7")
      assert length(countries) == 7
    end

    test "returns empty list for invalid union" do
      assert BeamLabCountries.Unions.member_countries("invalid") == []
    end
  end

  describe "filter_by/2" do
    test "filters by type" do
      military = BeamLabCountries.Unions.filter_by(:type, :military)
      assert length(military) == 1
      assert Enum.any?(military, &(&1.code == "nato"))
    end

    test "filters by economic_political type" do
      unions = BeamLabCountries.Unions.filter_by(:type, :economic_political)
      codes = Enum.map(unions, & &1.code)
      assert "eu" in codes
      assert "asean" in codes
    end
  end

  describe "exists?/1" do
    test "returns true for valid union" do
      assert BeamLabCountries.Unions.exists?("eu")
      assert BeamLabCountries.Unions.exists?("nato")
      assert BeamLabCountries.Unions.exists?("african_union")
    end

    test "returns false for invalid union" do
      refute BeamLabCountries.Unions.exists?("invalid")
    end

    test "is case insensitive" do
      assert BeamLabCountries.Unions.exists?("EU")
      assert BeamLabCountries.Unions.exists?("Eu")
    end
  end
end
