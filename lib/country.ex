defmodule BeamLabCountries.Country do
  @moduledoc """
  Country struct.

  `eu_member` and `eea_member` are always booleans (`false` for non-members).
  `timezones` is a list of IANA time zone identifiers (e.g. `"Europe/Tallinn"`),
  in the order used by the IANA `zone.tab` file.

  ## Number, date and currency formats

  `decimal_separator`, `thousands_separator`, `date_format` and `currency_format` describe how
  the country writes numbers and dates, taken from [Unicode CLDR](https://cldr.unicode.org)
  for the country's main language (`number_format_locale`, e.g. `"de-CH"` for Switzerland).
  Countries with several languages get one format; Belgian French and Dutch texts, for example,
  can differ from it.

    * `decimal_separator` / `thousands_separator` - the separator characters. Some are
      non-breaking spaces (`"\\u00A0"`, `"\\u202F"`), as in CLDR, so a number is never split across lines.
    * `date_format` - the short date with the tokens `YYYY`, `MM`/`M` and `DD`/`D`, e.g.
      `"DD.MM.YYYY"`, `"M/D/YYYY"`. Years always have four digits.
    * `currency_format` - the position of the amount and the currency symbol, using the same
      `{{...}}` placeholders as `address_format`: `"{{amount}} {{symbol}}"` or `"{{symbol}}{{amount}}"`.

  The separators are those of the Latin digits `0-9`, also where CLDR uses native digits.
  """

  @type t :: %__MODULE__{
          number: String.t() | nil,
          alpha2: String.t(),
          alpha3: String.t(),
          currency: String.t() | nil,
          name: String.t(),
          short_name: String.t() | nil,
          flag: String.t() | nil,
          unofficial_names: [String.t()] | nil,
          continent: String.t() | nil,
          region: String.t() | nil,
          subregion: String.t() | nil,
          geo: map() | nil,
          world_region: String.t() | nil,
          country_code: String.t() | nil,
          phone_prefix: String.t() | nil,
          national_destination_code_lengths: [integer()] | nil,
          national_number_lengths: [integer()] | nil,
          international_prefix: String.t() | nil,
          national_prefix: String.t() | nil,
          ioc: String.t() | nil,
          gec: String.t() | nil,
          un_locode: String.t() | nil,
          languages_official: [String.t()] | nil,
          languages_spoken: [String.t()] | nil,
          language_locales: map() | nil,
          nationality: String.t() | nil,
          address_format: String.t() | nil,
          dissolved_on: String.t() | nil,
          eu_member: boolean(),
          eea_member: boolean(),
          alt_currency: String.t() | nil,
          vat_rates: map() | nil,
          postal_code: boolean() | nil,
          currency_code: String.t() | nil,
          start_of_week: String.t() | nil,
          subdivision_type: String.t() | nil,
          timezones: [String.t()],
          number_format_locale: String.t() | nil,
          decimal_separator: String.t() | nil,
          thousands_separator: String.t() | nil,
          date_format: String.t() | nil,
          currency_format: String.t() | nil
        }

  defstruct [
    :number,
    :alpha2,
    :alpha3,
    :currency,
    :name,
    :short_name,
    :flag,
    :unofficial_names,
    :continent,
    :region,
    :subregion,
    :geo,
    :world_region,
    :country_code,
    :phone_prefix,
    :national_destination_code_lengths,
    :national_number_lengths,
    :international_prefix,
    :national_prefix,
    :ioc,
    :gec,
    :un_locode,
    :languages_official,
    :languages_spoken,
    :language_locales,
    :nationality,
    :address_format,
    :dissolved_on,
    :alt_currency,
    :vat_rates,
    :postal_code,
    :currency_code,
    :start_of_week,
    :subdivision_type,
    :number_format_locale,
    :decimal_separator,
    :thousands_separator,
    :date_format,
    :currency_format,
    eu_member: false,
    eea_member: false,
    timezones: []
  ]
end
