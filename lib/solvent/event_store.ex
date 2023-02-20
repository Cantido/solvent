defmodule Solvent.EventStore do
  @moduledoc """
  Storage for events.

  This module delegates to the module given by Solvent's application configuration.
  By default, an ETS table is used for the event store.
  To change it, set the `:event_store` config for the `:solvent` app.

      config :solvent,
        event_store: Solvent.EventStore.ETS

  Any module configured in this way must implement the `Solvent.EventStore.Base` behaviour.
  """


  @doc """
  Initialize the configured store.
  """
  def init do
    apply(store(), :init, [])
  end

  @doc """
  Insert an event into the event store, along with the ACKs to expect before the event is cleaned up.
  """
  def insert(event, expected_acks) do
    apply(store(), :insert, [event, expected_acks])
  end

  @doc """
  Get an event by ID. Returns `{:ok, event}` or `:error`.
  """
  def fetch(event_id) do
    apply(store(), :fetch, [event_id])
  end

  @doc """
  Get an event by ID. Raises if the event does not exist.
  """
  def fetch!(event_id) do
    apply(store(), :fetch!, [event_id])
  end

  @doc """
  Remove an event from the event store.
  """
  def delete(event_id) do
    apply(store(), :delete, [event_id])
  end

  @doc """
  Remove all events from the event store.
  """
  def delete_all do
    apply(store(), :delete_all, [])
  end

  @doc """
  Acknowledge that an event was processed, allowing it to be cleaned up.
  """
  def ack({event_source, event_id}, listener_id) do
    apply(store(), :ack, [{event_source, event_id}, listener_id])
  end

  defp store do
    Application.get_env(:solvent, :event_store, Solvent.EventStore.ETS)
  end
end
