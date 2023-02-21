defmodule Solvent.Filter.Suffix do
  @moduledoc """
  A filter that matches property strings that end with the given value.
  """

  @type t :: %__MODULE__{
          properties: %{Solvent.Event.property_key() => Solvent.Event.property_value()}
        }

  defstruct properties: %{}

  defimpl Solvent.Filter do
    def match?(filter, event) do
      Enum.all?(filter.properties, fn {key, value} ->
        String.ends_with?(Map.get(event, key), value)
      end)
    end
  end
end
