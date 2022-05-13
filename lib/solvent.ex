defmodule Solvent do
  @moduledoc """
  Documentation for `Solvent`.
  """

  def subscribe(bus, id, match_type, fun) do
    Solvent.EventBus.subscribe(bus, id, match_type, fun)
  end

  def publish(bus, type, opts \\ []) do
    event = %Solvent.Event{
      id: Keyword.get(opts, :id, UUID.uuid4()),
      source: "Solvent",
      type: type,
    }
    |> struct!(opts)

    Solvent.EventBus.publish(bus, event)
  end
end
