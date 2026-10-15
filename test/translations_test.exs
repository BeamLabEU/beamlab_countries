defmodule BeamLabCountries.TranslationsTest do
  use ExUnit.Case, async: true
  doctest BeamLabCountries.Translations

  alias BeamLabCountries.Translations

  # A blank or missing name doesn't count as a translation.
  defp translated?(name), do: is_binary(name) and String.trim(name) != ""

  describe "get_name/2" do
    test "returns translated country name" do
      assert Translations.get_name("DE", "fr") == "Allemagne"
      assert Translations.get_name("US", "zh") == "美国"
    end

    test "is case insensitive for country code and locale" do
      assert Translations.get_name("de", "FR") == "Allemagne"
    end

    test "covers every country in Estonian" do
      assert Translations.get_name("EE", "et") == "Eesti"
      assert Translations.get_name("FI", "et") == "Soome"
      assert Translations.get_name("GB", "et") == "Ühendkuningriik"

      # Held to the same bar as English: every country with an English
      # name must also have an Estonian one.
      untranslated =
        BeamLabCountries.all()
        |> Enum.map(& &1.alpha2)
        |> Enum.filter(&translated?(Translations.get_name(&1, "en")))
        |> Enum.reject(&translated?(Translations.get_name(&1, "et")))

      assert untranslated == []
    end

    test "translates Netherlands Antilles where names are known" do
      assert Translations.get_name("AN", "en") == "Netherlands Antilles"
      assert Translations.get_name("AN", "de") == "Niederländische Antillen"
      assert Translations.get_name("AN", "es") == "Antillas Holandesas"
      assert Translations.get_name("AN", "et") == "Hollandi Antillid"
      assert Translations.get_name("AN", "fr") == "Antilles néerlandaises"
      assert Translations.get_name("AN", "ja") == "オランダ領アンティル"
      assert Translations.get_name("AN", "nl") == "Nederlandse Antillen"
      assert Translations.get_name("AN", "ru") == "Нидерландские Антильские острова"
    end

    test "returns nil for unknown country or locale" do
      assert Translations.get_name("XX", "en") == nil
      assert Translations.get_name("DE", "xx") == nil
    end
  end

  describe "get_name/3" do
    test "reduces regional locales to their language" do
      assert Translations.get_name("DE", "pl-PL") == Translations.get_name("DE", "pl")
      assert Translations.get_name("DE", "pl_PL") == Translations.get_name("DE", "pl")
    end

    test "falls back to the given locale" do
      assert Translations.get_name("PL", "xx") == nil
      assert Translations.get_name("PL", "xx", fallback: "en") == "Poland"
      assert Translations.get_name("XX", "de", fallback: "en") == nil
    end

    test "is nil-safe" do
      assert Translations.get_name(nil, "en") == nil
      assert Translations.get_name("PL", nil) == nil
      refute Translations.locale_supported?(nil)
      assert Translations.get_name("PL", "xx", fallback: false) == nil
      assert Translations.get_name("PL", "xx", fallback: 123) == nil
      assert Translations.get_name("PL", "xx", fallback: "EN_us") == "Poland"
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
    test "lists 23 sorted locales including Estonian and the newest additions" do
      locales = Translations.supported_locales()
      assert length(locales) == 23
      assert locales == Enum.sort(locales)
      assert Enum.all?(~w(et hi tr th vi id cs ro), &(&1 in locales))
    end

    test "every supported locale names every country" do
      for locale <- Translations.supported_locales(), country <- BeamLabCountries.all() do
        assert Translations.get_name(country.alpha2, locale),
               "#{country.alpha2} has no #{locale} name"
      end
    end

    test "locale_supported?/1 is case insensitive" do
      assert Translations.locale_supported?("JA")
      refute Translations.locale_supported?("xx")
    end
  end
end
