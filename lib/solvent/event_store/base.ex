defmodule Solvent.EventStore.Base do
  @moduledoc """
  The definition of an event store module.

  Modules using this behavior can be used with the `Solvent.EventStore` module to publish and fetch events.
  """
  alias Solvent.Event

  @type event_id :: String.t()
  @type subscriber_id:: String.t()

  @callback init() :: :ok
  @callback fetch(event_id()) :: {:ok, Event.t()} | :error
  @callback fetch!(event_id()) :: Event.t()
  @callback insert(Event.t(), list(subscriber_id())) :: :ok
  @callback delete(event_id()) :: :ok
  @callback delete_all() :: :ok
  @callback ack(event_id(), subscriber_id()) :: :ok
end
