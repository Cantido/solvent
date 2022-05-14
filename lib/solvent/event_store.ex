defmodule Solvent.EventStore do
  def fetch(id) do
    case :ets.lookup(:solvent_event_store, id) do
      [{_id, event}] -> {:ok, event}
      _ -> :error
    end
  end

  def insert(event) do
    true = :ets.insert(:solvent_event_store, {event.id, event})
    :ok
  end
end
