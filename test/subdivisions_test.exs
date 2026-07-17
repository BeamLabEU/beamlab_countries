defmodule BeamLabCountries.SubdivisionsTest do
  use ExUnit.Case, async: true
  doctest BeamLabCountries.Subdivisions

  describe "all/1" do
    test "accepts an alpha2 code, case-insensitive" do
      subdivisions = BeamLabCountries.Subdivisions.all("US")
      assert length(subdivisions) == 60
      assert BeamLabCountries.Subdivisions.all("us") == subdivisions
    end

    test "returns empty list for country without subdivision data" do
      assert BeamLabCountries.Subdivisions.all("XX") == []
    end

    test "path traversal attempts are inert" do
      assert BeamLabCountries.Subdivisions.all("../unions") == []
      assert BeamLabCountries.Subdivisions.get("../unions", "eu") == nil
    end
  end

  describe "get/2" do
    test "is case insensitive for country code and subdivision ID" do
      assert BeamLabCountries.Subdivisions.get("us", "ca") ==
               BeamLabCountries.Subdivisions.get("US", "CA")
    end

    test "returns subdivision by country code and subdivision ID" do
      assert %BeamLabCountries.Subdivision{id: "CA", name: "California"} =
               BeamLabCountries.Subdivisions.get("US", "CA")
    end

    test "returns subdivision when given a country struct" do
      country = BeamLabCountries.get("US")

      assert %BeamLabCountries.Subdivision{id: "TX", name: "Texas"} =
               BeamLabCountries.Subdivisions.get(country, "TX")
    end

    test "returns nil for non-existent subdivision" do
      assert BeamLabCountries.Subdivisions.get("US", "XX") == nil
    end

    test "returns nil for non-existent country" do
      assert BeamLabCountries.Subdivisions.get("XX", "01") == nil
    end

    test "returns subdivision with translations" do
      subdivision = BeamLabCountries.Subdivisions.get("DE", "BY")

      assert subdivision.name == "Bayern"
      assert is_map(subdivision.translations)
    end
  end
end
