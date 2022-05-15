defmodule Solvent.EventStore do
  @moduledoc """
  ETS-based storage for `Solvent.Event` objects.
  """

  @doc """
  Fetch an event by ID.
  """
  def fetch(id) do
    case :ets.lookup(:solvent_event_store, id) do
      [{_id, event}] -> {:ok, event}
      _ -> :error
    end
  end

  @doc """
  Insert a new event into storage.

  This does not activate any subscribers, use `Solvent.publish/2` for that.
  """
  def insert(event) do
    true = :ets.insert(:solvent_event_store, {event.id, event})
    :ok
  end

  @doc """
  Remove an event from storage.
  """
  def delete(event_id) do
    true = :ets.delete(:solvent_event_store, event_id)
    :ok
  end
end
