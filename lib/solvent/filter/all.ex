defmodule Solvent.Filter.All do
  @moduledoc """
  A filter that matches when all subfilters match.
  """
  defstruct subfilters: []

  defimpl Solvent.Filter do
    def match?(filter, event) do
      Enum.all?(filter.subfilters, fn subfilter ->
        Solvent.Filter.match?(subfilter, event)
      end)
    end
  end
end
