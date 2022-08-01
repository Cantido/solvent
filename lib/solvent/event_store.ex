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

  @behaviour Solvent.EventStore.Base

  @impl true
  def init do
    apply(store(), :init, [])
  end

  @impl true
  def insert(event, expected_acks) do
    apply(store(), :insert, [event, expected_acks])
  end

  @impl true
  def fetch(event_id) do
    apply(store(), :fetch, [event_id])
  end

  @impl true
  def fetch!(event_id) do
    apply(store(), :fetch!, [event_id])
  end

  @impl true
  def delete(event_id) do
    apply(store(), :delete, [event_id])
  end

  @impl true
  def delete_all do
    apply(store(), :delete_all, [])
  end

  @impl true
  def ack(event_id, listener_id) do
    apply(store(), :ack, [event_id, listener_id])
  end

  defp store do
    Application.get_env(:solvent, :event_store, Solvent.EventStore.ETS)
  end
end
