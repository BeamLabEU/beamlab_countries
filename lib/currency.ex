defmodule BeamLabCountries.Currency do
  @moduledoc """
  Currency struct representing ISO 4217 currency data.
  """

  @type t :: %__MODULE__{
          code: String.t() | nil,
          name: String.t() | nil,
          name_plural: String.t() | nil,
          symbol: String.t() | nil,
          symbol_native: String.t() | nil,
          decimal_digits: non_neg_integer() | nil
        }

  defstruct [
    :code,
    :name,
    :name_plural,
    :symbol,
    :symbol_native,
    :decimal_digits
  ]
end
