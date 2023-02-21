defmodule Solvent.Filter.Exact do
  @moduledoc """
  A filter that matches a property with a certain value.
  """

  @type t :: %__MODULE__{
          properties: %{Solvent.Event.property_key() => String.t()}
        }
  defstruct properties: %{}

  defimpl Solvent.Filter do
    def match?(filter, event) do
      Enum.all?(filter.properties, fn {key, value} ->
        Map.get(event, key) == value
      end)
    end
  end
end
