defmodule BeamLabCountries.CitiesTest do
  use ExUnit.Case, async: true
  doctest BeamLabCountries.Cities

  alias BeamLabCountries.{Cities, City, Subdivisions, Translations}

  @city_files Path.wildcard(Path.join(["priv", "data", "cities", "*.json"]))

  describe "data" do
    test "files are named after uppercase alpha2 codes of known countries" do
      assert length(@city_files) > 200

      for file <- @city_files do
        code = Path.basename(file, ".json")
        assert code =~ ~r/\A[A-Z]{2}\z/, "bad file name: #{file}"
        assert BeamLabCountries.get(code), "no country for #{file}"
        assert [_ | _] = Cities.for_country(code), "#{file} is unreachable"
      end
    end

    test "IDs are unique and every city has the required fields" do
      ids = Enum.map(Cities.all(), & &1.id)
      assert ids == Enum.uniq(ids)

      for %City{} = city <- Cities.all() do
        assert is_integer(city.id) and city.id > 0
        assert is_binary(city.name) and city.name != ""
        assert is_binary(city.native_name) and city.native_name != ""
        assert is_integer(city.population) and city.population >= 0
        assert city.latitude >= -90 and city.latitude <= 90
        assert city.longitude >= -180 and city.longitude <= 180
        assert is_boolean(city.capital)
        assert city.timezone =~ ~r{\A[A-Za-z]+/[A-Za-z0-9_+\-/]+\z}
      end
    end

    test "translations use supported locales and differ from the English name" do
      locales = Translations.supported_locales()

      for city <- Cities.all(), {locale, translated} <- city.translations do
        assert locale in locales, "#{city.name}: unknown locale #{locale}"
        refute locale == "en", "#{city.name}: English must use the canonical name"
        assert is_binary(translated) and translated != city.name
      end
    end

    test "cities are sorted by population, largest first" do
      for code <- ["US", "DE", "EE", "CA"] do
        populations = code |> Cities.for_country(limit: :all) |> Enum.map(& &1.population)
        assert populations == Enum.sort(populations, :desc)
      end
    end

    test "countries have at most one capital, and non-US/CA cities have no subdivision" do
      for country <- BeamLabCountries.all() do
        cities = Cities.for_country(country, limit: :all)
        assert Enum.count(cities, & &1.capital) <= 1
        assert Enum.all?(cities, &(&1.country == country.alpha2))

        if country.alpha2 not in ["US", "CA"] do
          assert Enum.all?(cities, &is_nil(&1.subdivision))
          assert length(cities) <= 11
        end
      end
    end

    test "US and Canadian subdivisions exist" do
      for code <- ["US", "CA"], city <- Cities.for_country(code, limit: :all) do
        assert city.subdivision, "#{city.name} has no subdivision"
        assert Subdivisions.get(code, city.subdivision), "#{city.name}: #{city.subdivision}"
      end
    end

    test "every Canadian province and territory has at least ten cities" do
      for subdivision <- Subdivisions.all("CA") do
        cities = Cities.for_subdivision("CA", subdivision.id)
        assert length(cities) >= 10, "#{subdivision.id} has only #{length(cities)} cities"
        assert length(Enum.uniq_by(cities, & &1.id)) == length(cities)
        assert length(Cities.for_subdivision("CA", subdivision.id, limit: 10)) == 10
      end
    end

    test "every US state has at least ten cities" do
      non_states = ~w(AA AE AP AS DC GU MP PR UM VI)
      states = Enum.reject(Subdivisions.all("US"), &(&1.id in non_states))
      assert length(states) == 50

      for state <- states do
        cities = Cities.for_subdivision("US", state.id)
        assert length(cities) >= 10, "#{state.id} has only #{length(cities)} cities"
        assert length(Cities.for_subdivision("US", state.id, limit: 10)) == 10
      end
    end
  end

  describe "for_country/2" do
    test "defaults to ten cities, :limit changes that" do
      assert length(Cities.for_country("US")) == 10
      assert length(Cities.for_country("US", limit: :all)) > 100
      assert length(Cities.for_country("DE", limit: 3)) == 3
      assert Cities.for_country("DE", limit: 0) == []
    end

    test "accepts a country struct and is case-insensitive" do
      assert Cities.for_country(BeamLabCountries.get("FR")) == Cities.for_country("fr")
    end

    test "invalid limits raise a useful error for country and subdivision lookups" do
      for limit <- [-1, 1.5, nil, "10", :invalid] do
        assert_raise ArgumentError, ~r/:limit must be/, fn ->
          Cities.for_country("DE", limit: limit)
        end

        assert_raise ArgumentError, ~r/:limit must be/, fn ->
          Cities.for_subdivision("US", "CA", limit: limit)
        end
      end
    end

    test "includes the capital even when it is not among the largest" do
      assert %City{name: "Washington D.C."} = Cities.capital("US")
      assert Cities.capital("US") in Cities.for_country("US", limit: :all)
      assert Cities.capital("CH").name == "Bern"
    end

    test "is nil-safe" do
      assert Cities.for_country(nil) == []
      assert Cities.for_subdivision(nil, "CA") == []
      assert Cities.for_subdivision("US", nil) == []
      assert Cities.capital(nil) == nil
      assert Cities.get(nil) == nil
    end
  end

  describe "for_subdivision/3" do
    test "returns the largest cities of a state or province" do
      assert ["New York" | _] = Cities.for_subdivision("US", "NY") |> Enum.map(& &1.name)
      assert Cities.for_subdivision("CA", "QC") |> hd() |> Map.get(:name) == "Montreal"
      assert length(Cities.for_subdivision("US", "TX", limit: 2)) == 2
    end

    test "accepts a country struct and is case-insensitive" do
      country = BeamLabCountries.get("US")
      assert Cities.for_subdivision(country, "ca") == Cities.for_subdivision("us", "CA")
    end
  end

  describe "get_name/2" do
    test "returns the translation, falling back to the English name" do
      vienna = Cities.get(2_761_369)
      assert Cities.get_name(vienna, "de") == "Wien"
      assert Cities.get_name(vienna, "DE-at") == "Wien"
      assert Cities.get_name(vienna, "de_AT") == "Wien"
      assert Cities.get_name(vienna, "xx") == "Vienna"
      assert Cities.get_name(vienna, "en") == "Vienna"
      assert Cities.get_name(vienna, nil) == "Vienna"
    end

    test "names differ by language across Europe" do
      names = for l <- ~w(en de fr es), do: Cities.get_name(Cities.capital("CZ"), l)
      assert names == ["Prague", "Prag", "Prague", "Praga"]
    end

    test "English names are canonical and preferred short names beat unpreferred alternatives" do
      for city <- Cities.all() do
        assert Cities.get_name(city, "en-US") == city.name
      end

      assert Cities.get(5_454_711).native_name == "Albuquerque"
      assert Cities.get_name(Cities.get(5_128_581), "en") == "New York"
    end
  end
end
