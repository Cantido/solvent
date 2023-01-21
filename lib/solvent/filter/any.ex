defmodule Solvent.Filter.Any do
  @moduledoc """
  A filter that matches when at least one of the given subfilters matches.
  """
  defstruct subfilters: []

  defimpl Solvent.Filter do
    def match?(filter, event) do
      Enum.any?(filter.subfilters, fn subfilter ->
        Solvent.Filter.match?(subfilter, event)
      end)
    end
  end
end
