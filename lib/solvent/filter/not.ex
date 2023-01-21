defmodule Solvent.Filter.Not do
  @moduledoc """
  A filter that inverts another filter.
  """
  defstruct [:subfilter]

  defimpl Solvent.Filter do
    def match?(filter, event) do
      not Solvent.Filter.match?(filter.subfilter, event)
    end
  end
end
