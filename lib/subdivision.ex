defmodule BeamLabCountries.Subdivision do
  @moduledoc """
  Country Subdivision struct.
  """

  defstruct [:id, :name, :unofficial_names, :translations, :geo]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t() | nil,
          unofficial_names: term() | nil,
          translations: %{optional(atom()) => String.t()} | nil,
          geo: map() | nil
        }
end
