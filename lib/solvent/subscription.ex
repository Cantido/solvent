defmodule Solvent.Subscription do
  alias Solvent.Filter

  defstruct [
    :id,
    :sink,
    :filter,
    :source
  ]

  def match?(subscription, event) do
    source_match?(subscription.source, event) and filter_match?(subscription.filter, event)
  end

  def source_match?(nil, _event), do: true
  def source_match?(source, event), do: source == event.source

  def filter_match?(nil, _event), do: true
  def filter_match?(filter, event), do: Filter.match?(filter, event)
end
