defmodule Solvent.Filter.Prefix do
  defstruct properties: %{}

  defimpl Solvent.Filter do
    def match?(filter, event) do
      Enum.all?(filter.properties, fn {key, value} ->
        String.starts_with?(Map.get(event, key), value)
      end)
    end
  end
end
