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


  def init do
    apply(store(), :init, [])
  end

  def insert(event, expected_acks) do
    apply(store(), :insert, [event, expected_acks])
  end

  def fetch(event_id) do
    apply(store(), :fetch, [event_id])
  end

  def fetch!(event_id) do
    apply(store(), :fetch!, [event_id])
  end

  def delete(event_id) do
    apply(store(), :delete, [event_id])
  end

  def delete_all do
    apply(store(), :delete_all, [])
  end

  def ack({event_source, event_id}, listener_id) do
    apply(store(), :ack, [{event_source, event_id}, listener_id])
  end

  defp store do
    Application.get_env(:solvent, :event_store, Solvent.EventStore.ETS)
  end
end
