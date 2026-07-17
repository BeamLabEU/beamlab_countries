defmodule BeamLabCountries.TranslationsTest do
  use ExUnit.Case, async: true
  doctest BeamLabCountries.Translations

  alias BeamLabCountries.Translations

  describe "get_name/2" do
    test "returns translated country name" do
      assert Translations.get_name("DE", "fr") == "Allemagne"
      assert Translations.get_name("US", "zh") == "美国"
    end

    test "is case insensitive for country code and locale" do
      assert Translations.get_name("de", "FR") == "Allemagne"
    end

    test "returns nil for unknown country or locale" do
      assert Translations.get_name("XX", "en") == nil
      assert Translations.get_name("DE", "xx") == nil
    end
  end

  describe "get_all_names/1" do
    test "returns a name for every supported locale" do
      names = Translations.get_all_names("IT")
      assert map_size(names) == length(Translations.supported_locales())
      assert names["en"] == "Italy"
    end

    test "omits locales without a name" do
      assert Translations.get_all_names("XX") == %{}
    end
  end

  describe "supported_locales/0 and locale_supported?/1" do
    test "lists 15 locales" do
      assert length(Translations.supported_locales()) == 15
    end

    test "locale_supported?/1 is case insensitive" do
      assert Translations.locale_supported?("JA")
      refute Translations.locale_supported?("xx")
    end
  end
end
