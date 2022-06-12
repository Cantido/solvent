defmodule Solvent.EventStore do
  @moduledoc """
  ETS-based storage for `Solvent.Event` objects.

  Events are stored using `insert/2`, along with an enumerable of subscriber IDs.
  The event is then stored until all subscribers call `ack/2` to acknowledge the event,
  after which point the event is deleted from the store.

  The event store is initialized by the Solvent supervisor,
  so no setup work is necessary to use the store.
  """

  require Logger

  @table_name :solvent_event_store
  @ack_table :solvent_event_pending_ack

  @doc false
  def init do
    :ets.new(@table_name, [:set, :public, :named_table])
    :ets.new(@ack_table, [:bag, :public, :named_table])
  end

  @doc """
  Fetch an event by ID.

  Returns `{:ok, event}` if the event exists, otherwise returns `:error`.
  """
  def fetch(id) do
    case :ets.lookup(@table_name, id) do
      [{_id, event}] -> {:ok, event}
      _ -> :error
    end
  end

  @doc """
  Fetches an event by ID, and raises an error if it is not in the event store.
  """
  def fetch!(id) do
    case fetch(id) do
      {:ok, event} -> event
      :error -> raise "Event with id #{inspect id} not found"
    end
  end


  @doc """
  Insert a new event into storage, along with all listeners that need to acknowledge it before it can be deleted.

  This does not activate any subscribers, use `Solvent.publish/2` for that.
  """
  def insert(event, pending_ack) do
    Enum.each(pending_ack, fn sub_id ->
      true = :ets.insert(@ack_table, {event.id, sub_id})
    end)

    true = :ets.insert(@table_name, {event.id, event})
    :ok
  end

  @doc """
  Remove an event from storage.
  """
  def delete(event_id) do
    true = :ets.delete(@table_name, event_id)
    :ok
  end

  @doc """
  Delete all events from the event store.
  """
  def delete_all do
    true = :ets.delete_all_objects(@table_name)
    true = :ets.delete_all_objects(@ack_table)
    :ok
  end

  @doc """
  Acknowledge that a listener has finished processing the event.
  """
  def ack(event_id, listener_id) do
    count_deleted = :ets.match_delete(@ack_table, {event_id, listener_id})
    count_pending = :ets.match(@ack_table, {event_id, :"$1"}) |> Enum.count()
    count_pending_all = :ets.match(@ack_table, {:all, :"$1"}) |> Enum.count()

    if count_pending == 0 && count_deleted > 0 do
      Logger.debug("Event #{event_id} has been acked by all subscribers. Deleting it.")
      delete(event_id)
    end

    :ok
  end
end
