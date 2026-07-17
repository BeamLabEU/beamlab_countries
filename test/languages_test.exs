defmodule BeamLabCountries.LanguagesTest do
  use ExUnit.Case, async: true
  doctest BeamLabCountries.Languages
  doctest BeamLabCountries.Language
  doctest BeamLabCountries.Locale

  alias BeamLabCountries.Language
  alias BeamLabCountries.Languages
  alias BeamLabCountries.Locale

  # ============================================================================
  # Base Language Tests (existing API)
  # ============================================================================

  describe "get_name/1" do
    test "returns English name for valid language code" do
      assert Languages.get_name("en") == "English"
      assert Languages.get_name("de") == "German"
      assert Languages.get_name("ja") == "Japanese"
      assert Languages.get_name("pl") == "Polish"
    end

    test "is case insensitive" do
      assert Languages.get_name("EN") == "English"
      assert Languages.get_name("De") == "German"
    end

    test "returns nil for invalid code" do
      assert Languages.get_name("invalid") == nil
      assert Languages.get_name("xyz") == nil
    end
  end

  describe "get_native_name/1" do
    test "returns native name for valid language code" do
      assert Languages.get_native_name("en") == "English"
      assert Languages.get_native_name("de") == "Deutsch"
      assert Languages.get_native_name("ja") == "日本語 (にほんご)"
      # Polish native name in data source includes formal name
      assert Languages.get_native_name("pl") =~ "polski"
    end

    test "is case insensitive" do
      assert Languages.get_native_name("DE") == "Deutsch"
    end

    test "returns nil for invalid code" do
      assert Languages.get_native_name("invalid") == nil
    end
  end

  describe "get/1" do
    test "returns Language struct for valid code" do
      language = Languages.get("en")
      assert %Language{} = language
      assert language.code == "en"
      assert language.name == "English"
      assert language.native_name == "English"
      assert language.family == "Indo-European"
    end

    test "returns nil for invalid code" do
      assert Languages.get("invalid") == nil
    end
  end

  describe "all/0" do
    test "returns all languages as Language structs" do
      languages = Languages.all()
      assert length(languages) == 184
      assert Enum.all?(languages, &match?(%Language{}, &1))
    end

    test "languages are sorted by name" do
      languages = Languages.all()
      names = Enum.map(languages, & &1.name)
      assert names == Enum.sort(names)
    end
  end

  describe "all_codes/0" do
    test "returns all language codes" do
      codes = Languages.all_codes()
      assert "en" in codes
      assert "de" in codes
      assert "ja" in codes
      assert length(codes) == 184
    end
  end

  describe "count/0" do
    test "returns count of languages" do
      assert Languages.count() == 184
    end
  end

  describe "valid?/1" do
    test "returns true for valid codes" do
      assert Languages.valid?("en")
      assert Languages.valid?("de")
      assert Languages.valid?("ja")
    end

    test "returns false for invalid codes" do
      refute Languages.valid?("invalid")
      refute Languages.valid?("xyz")
    end

    test "is case insensitive" do
      assert Languages.valid?("EN")
      assert Languages.valid?("De")
    end
  end

  # ============================================================================
  # Locale Tests (new API)
  # ============================================================================

  describe "get_locale/1" do
    test "returns Locale struct for valid locale code" do
      locale = Languages.get_locale("en-US")
      assert %Locale{} = locale
      assert locale.code == "en-US"
      assert locale.base_code == "en"
      assert locale.region_code == "US"
      assert locale.name == "English (United States)"
      assert locale.native_name == "English (US)"
      assert locale.flag == "🇺🇸"
      assert locale.country_name == "United States of America"
      assert locale.continent == "North America"
      assert locale.region == "Americas"
      assert locale.subregion == "Northern America"
    end

    test "returns Locale for various locales" do
      locale = Languages.get_locale("es-ES")
      assert locale.name == "Spanish (Spain)"
      assert locale.flag == "🇪🇸"
      assert locale.continent == "Europe"
      assert locale.region == "Europe"
      assert locale.subregion == "Southern Europe"

      locale = Languages.get_locale("pt-BR")
      assert locale.name == "Portuguese (Brazil)"
      assert locale.flag == "🇧🇷"
      assert locale.continent == "South America"
      assert locale.region == "Americas"

      locale = Languages.get_locale("de-DE")
      assert locale.name == "German (Germany)"
      assert locale.flag == "🇩🇪"
      assert locale.continent == "Europe"
      assert locale.subregion == "Western Europe"
    end

    test "returns nil for invalid locale" do
      assert Languages.get_locale("invalid") == nil
      assert Languages.get_locale("xx-YY") == nil
    end
  end

  describe "all_locales/0" do
    test "returns all locales as Locale structs" do
      locales = Languages.all_locales()
      refute Enum.empty?(locales)
      assert Enum.all?(locales, &match?(%Locale{}, &1))
    end

    test "locales are sorted by name" do
      locales = Languages.all_locales()
      names = Enum.map(locales, & &1.name)
      assert names == Enum.sort(names)
    end

    test "all locales have flags" do
      locales = Languages.all_locales()
      # Most locales should have flags (some obscure regions might not)
      with_flags = Enum.filter(locales, & &1.flag)
      assert length(with_flags) > 80
    end

    test "all locales have geographic data" do
      locales = Languages.all_locales()
      # All locales should have continent, region, and subregion
      with_continent = Enum.filter(locales, & &1.continent)
      with_region = Enum.filter(locales, & &1.region)
      with_subregion = Enum.filter(locales, & &1.subregion)

      assert length(with_continent) > 80
      assert length(with_region) > 80
      assert length(with_subregion) > 80
    end
  end

  describe "all_locale_codes/0" do
    test "returns all locale codes" do
      codes = Languages.all_locale_codes()
      assert "en-US" in codes
      assert "es-ES" in codes
      assert "pt-BR" in codes
    end
  end

  describe "locale_count/0" do
    test "returns count of locales" do
      assert Languages.locale_count() > 80
    end
  end

  describe "locales_for_language/1" do
    test "returns all locales for English" do
      locales = Languages.locales_for_language("en")
      codes = Enum.map(locales, & &1.code)
      assert "en-US" in codes
      assert "en-GB" in codes
      assert "en-AU" in codes
      assert "en-CA" in codes
    end

    test "returns all locales for Spanish" do
      locales = Languages.locales_for_language("es")
      codes = Enum.map(locales, & &1.code)
      assert "es-ES" in codes
      assert "es-MX" in codes
      assert "es-AR" in codes
      assert "es-CO" in codes
      assert length(locales) == 4
    end

    test "returns empty list for language with no locales defined" do
      locales = Languages.locales_for_language("xyz")
      assert locales == []
    end

    test "is case insensitive" do
      locales_lower = Languages.locales_for_language("en")
      locales_upper = Languages.locales_for_language("EN")
      assert length(locales_lower) == length(locales_upper)
    end
  end

  describe "valid_locale?/1" do
    test "returns true for valid locale codes" do
      assert Languages.valid_locale?("en-US")
      assert Languages.valid_locale?("es-ES")
      assert Languages.valid_locale?("pt-BR")
    end

    test "returns false for invalid locale codes" do
      refute Languages.valid_locale?("invalid")
      refute Languages.valid_locale?("xx-YY")
      # Base language codes are not valid locales unless explicitly defined
      refute Languages.valid_locale?("xyz")
    end
  end

  describe "parse_locale/1" do
    test "parses full locale codes" do
      assert Languages.parse_locale("en-US") == {"en", "US"}
      assert Languages.parse_locale("es-ES") == {"es", "ES"}
      assert Languages.parse_locale("pt-BR") == {"pt", "BR"}
      assert Languages.parse_locale("zh-CN") == {"zh", "CN"}
    end

    test "parses base language codes" do
      assert Languages.parse_locale("ja") == {"ja", nil}
      assert Languages.parse_locale("ko") == {"ko", nil}
    end

    test "lowercases base code" do
      assert Languages.parse_locale("EN-US") == {"en", "US"}
      assert Languages.parse_locale("JA") == {"ja", nil}
    end
  end

  # ============================================================================
  # Country-Language Association Tests
  # ============================================================================

  describe "countries_for_language/1" do
    test "returns countries where English is spoken" do
      countries = Languages.countries_for_language("en")
      country_names = Enum.map(countries, & &1.name)

      assert "United States of America" in country_names
      assert "United Kingdom of Great Britain and Northern Ireland" in country_names
      assert "Australia" in country_names
      assert "Canada" in country_names
      # English is spoken in many countries
      assert length(countries) > 50
    end

    test "returns countries where Spanish is spoken" do
      countries = Languages.countries_for_language("es")
      country_names = Enum.map(countries, & &1.name)

      assert "Spain" in country_names
      assert "Mexico" in country_names
      assert "Argentina" in country_names
    end

    test "is case insensitive" do
      countries_lower = Languages.countries_for_language("en")
      countries_upper = Languages.countries_for_language("EN")
      assert length(countries_lower) == length(countries_upper)
    end

    test "returns empty list for invalid language" do
      assert Languages.countries_for_language("xyz") == []
    end

    test "countries are sorted by name" do
      countries = Languages.countries_for_language("en")
      names = Enum.map(countries, & &1.name)
      assert names == Enum.sort(names)
    end
  end

  describe "country_names_for_language/1" do
    test "returns country names where English is spoken" do
      names = Languages.country_names_for_language("en")

      assert "United States of America" in names
      assert "United Kingdom of Great Britain and Northern Ireland" in names
      assert length(names) > 50
    end

    test "returns empty list for invalid language" do
      assert Languages.country_names_for_language("xyz") == []
    end
  end

  describe "flags_for_language/1" do
    test "returns flags for countries where English is spoken" do
      flags = Languages.flags_for_language("en")

      assert "🇺🇸" in flags
      assert "🇬🇧" in flags
      assert "🇦🇺" in flags
      assert length(flags) > 50
    end

    test "returns empty list for invalid language" do
      assert Languages.flags_for_language("xyz") == []
    end
  end
end
