# SPDX-FileCopyrightText: 2023 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Solvent.Filter.Any do
  @moduledoc """
  A filter that matches when at least one of the given subfilters matches.
  """

  @type t :: %__MODULE__{
          subfilters: [Solvent.Filter.t()]
        }
  defstruct subfilters: []

  defimpl Solvent.Filter do
    def match?(filter, event) do
      Enum.any?(filter.subfilters, fn subfilter ->
        Solvent.Filter.match?(subfilter, event)
      end)
    end
  end
end
