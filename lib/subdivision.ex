defmodule BeamLabCountries.Subdivision do
  @moduledoc """
  Country Subdivision struct.

  ## Fields

  - `id` - subdivision code within its country (e.g. `"CA"` for California). IDs ending in
    `~` (e.g. `"X1~"`) mark places that are not part of ISO 3166-2.
  - `name` - English name. Falls back to the `:en` translation when the data has no
    dedicated name.
  - `unofficial_names` - alternative names, always a list.
  - `translations` - map of language atom to name (e.g. `%{de: "Bayern"}`).
  - `geo` - coordinates and bounding box, if known.
  """

  defstruct [:id, :name, :translations, :geo, unofficial_names: []]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t() | nil,
          unofficial_names: [String.t()],
          translations: %{optional(atom()) => String.t()} | nil,
          geo: map() | nil
        }
end
