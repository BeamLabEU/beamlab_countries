defmodule BeamLabCountries.SubdivisionsTest do
  use ExUnit.Case, async: true

  describe "get/2" do
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
