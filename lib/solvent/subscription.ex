defmodule Solvent.Subscription do
  alias Solvent.Filter

  defstruct [
    :id,
    :sink,
    :filter,
    :source,
    types: []
  ]

  def match?(subscription, event) do
    source_match?(subscription.source, event) and (filter_match?(subscription.filter, event) or types_match?(subscription.types, event))
  end

  def source_match?(nil, _event), do: true
  def source_match?(source, event), do: source == event.source

  def types_match?([], _event), do: true
  def types_match?(types, event), do: event.type in types

  def filter_match?(nil, _event), do: true
  def filter_match?(filter, event), do: Filter.match?(filter, event)
end
