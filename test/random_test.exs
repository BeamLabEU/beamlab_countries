defmodule BeamLabCountries.RandomTest do
  use ExUnit.Case, async: true

  describe "country/0" do
    test "returns a random country struct" do
      assert %BeamLabCountries.Country{} = BeamLabCountries.Random.country()
    end

    test "returns a country with a valid alpha2 code" do
      country = BeamLabCountries.Random.country()
      assert BeamLabCountries.get(country.alpha2) != nil
    end
  end

  describe "flag/0" do
    test "returns a string" do
      assert is_binary(BeamLabCountries.Random.flag())
    end

    test "returns a flag that belongs to an existing country" do
      flag = BeamLabCountries.Random.flag()
      assert BeamLabCountries.exists?(:flag, flag)
    end
  end
end
