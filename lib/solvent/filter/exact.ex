defmodule Solvent.Filter.Exact do
  defstruct properties: %{}

  defimpl Solvent.Filter do
    def match?(filter, event) do
      Enum.all?(filter.properties, fn {key, value} ->
        Map.get(event, key) == value
      end)
    end
  end
end
