defmodule Solvent.Filter.Any do
  defstruct subfilters: []

  defimpl Solvent.Filter do
    def match?(filter, event) do
      Enum.any?(filter.subfilters, fn subfilter ->
        Solvent.Filter.match?(subfilter, event)
      end)
    end
  end
end
