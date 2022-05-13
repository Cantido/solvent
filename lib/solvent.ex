defmodule Solvent do
  @moduledoc """
  Documentation for `Solvent`.
  """

  def subscribe(bus, id, match_type, fun) do
    Solvent.EventBus.subscribe(bus, id, match_type, fun)
  end

  def publish(bus, type, data, opts \\ []) do
    event = %Solvent.Event{
      id: Keyword.get(opts, :id, make_ref()),
      source: "Solvent",
      type: type,
      data: data
    }
    Solvent.EventBus.publish(bus, type, event)
  end
end
