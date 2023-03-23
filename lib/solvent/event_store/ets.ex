# SPDX-FileCopyrightText: 2023 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Solvent.EventStore.ETS do
  @moduledoc """
  ETS-based storage for `Solvent.Event` objects.

  Events are stored using `insert/2`, along with an enumerable of subscriber IDs.
  The event is then stored until all subscribers call `ack/2` to acknowledge the event,
  after which point the event is deleted from the store.

  The event store is initialized by the Solvent supervisor,
  so no setup work is necessary to use the store.

  This event store can send messages to other processes when it changes,
  see `debug_subscribe/1` for more information.
  """

  require Logger

  @behaviour Solvent.EventStore.Base

  @table_name :solvent_event_store
  @ack_table :solvent_event_pending_ack
  @debug_subscribers_table :solvent_debug_subscribers

  @doc false
  @impl true
  def init do
    :ets.new(@table_name, [:set, :public, :named_table])
    :ets.new(@ack_table, [:bag, :public, :named_table])
    :ets.new(@debug_subscribers_table, [:set, :public, :named_table])
  end

  @doc """
  Fetch an event by `{source, id}` tuple.

  Returns `{:ok, event}` if the event exists, otherwise returns `:error`.
  """
  @impl true
  def fetch(id) do
    case :ets.lookup(@table_name, id) do
      [{_id, event}] -> {:ok, event}
      _ -> :error
    end
  end

  @doc """
  Fetches an event by `{source, id}` tuple, and raises an error if it is not in the event store.
  """
  @impl true
  def fetch!(id) do
    case fetch(id) do
      {:ok, event} -> event
      :error -> raise "Event with id #{inspect(id)} not found"
    end
  end

  @doc """
  Insert a new event into storage, along with all listeners that need to acknowledge it before it can be deleted.

  This does not activate any subscribers, use `Solvent.publish/2` for that.
  """
  @impl true
  def insert(event, pending_acks)

  def insert(_event, []) do
    :ok
  end

  def insert(event, pending_ack) do
    Enum.each(pending_ack, fn sub_id ->
      unless is_binary(sub_id) do
        raise ArgumentError, "Pending acknowledgement list must be subscriber IDs"
      end

      true = :ets.insert(@ack_table, {{event.source, event.id}, sub_id})
    end)

    true = :ets.insert(@table_name, {{event.source, event.id}, event})
    notify_debug_subscribers({:inserted, event, pending_ack})
    :ok
  end

  @doc """
  Remove an event from storage.
  """
  @impl true
  def delete({event_source, event_id}) do
    true = :ets.delete(@table_name, {event_source, event_id})
    notify_debug_subscribers({:deleted, {event_source, event_id}})
    :ok
  end

  @doc """
  Delete all events from the event store.
  """
  @impl true
  def delete_all do
    true = :ets.delete_all_objects(@table_name)
    true = :ets.delete_all_objects(@ack_table)
    notify_debug_subscribers(:all_deleted)
    :ok
  end

  @doc """
  Acknowledge that a listener has finished processing the event.
  """
  @impl true
  def ack(event_handle, subscription_id) when is_binary(subscription_id) do
    true = :ets.match_delete(@ack_table, {event_handle, subscription_id})

    notify_debug_subscribers({:acked, event_handle, subscription_id})

    count_pending = :ets.match(@ack_table, {event_handle, :"$1"}) |> Enum.count()

    if count_pending == 0 do
      Logger.debug(
        "Event #{inspect(event_handle)} has been acked by all subscribers. Deleting it."
      )

      delete(event_handle)
    end

    :ok
  end

  @doc """
  Subscribe a process to receive messages when the table changes.

  The list of processes subscribed by this function is _not_ cleared when `delete_all/0` is called.
  Call `debug_unsubscribe/1` to remove a process from the debug subscribers list.

  The given PID will be sent the following tuples when the corresponding events occur:

  - `{:inserted, event, ack_ids}` - sent when an event is inserted. If no acknowledgement IDs were provided, then this message _will not_ be sent.
  - `{:deleted, event_handle}` - sent when an event is removed from the table.
  - `:all_deleted` - sent when the event store is cleared.
  - `{:acked, event_handle, subscription_id}` - sent when a subscriber acknowledges an event.
  """
  @spec debug_subscribe(pid()) :: :ok
  def debug_subscribe(pid) do
    true = :ets.insert(@debug_subscribers_table, {pid})
    :ok
  end

  @doc """
  Remove a process from the list of debug subscribers.
  The given process will no longer receive messages when the event store changes.
  """
  @spec debug_unsubscribe(pid()) :: :ok
  def debug_unsubscribe(pid) do
    true = :ets.match_delete(@debug_subscribers_table, {pid})
    :ok
  end

  defp notify_debug_subscribers(payload) do
    :ets.match(@debug_subscribers_table, :"$1")
    |> List.flatten()
    |> Enum.each(fn {pid} ->
      send(pid, payload)
    end)
  end
end
