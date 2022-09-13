defmodule Solvent.Filter.All do
  defstruct subfilters: []

  defimpl Solvent.Filter do
    def match?(filter, event) do
      Enum.all?(filter.subfilters, fn subfilter ->
        Solvent.Filter.match?(subfilter, event)
      end)
    end
  end
end
