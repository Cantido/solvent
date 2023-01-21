defmodule Solvent.Filter.Exact do
  @moduledoc """
  A filter that matches a property with a certain value.
  """
  defstruct properties: %{}

  defimpl Solvent.Filter do
    def match?(filter, event) do
      Enum.all?(filter.properties, fn {key, value} ->
        Map.get(event, key) == value
      end)
    end
  end
end
