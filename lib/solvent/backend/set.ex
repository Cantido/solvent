defmodule Solvent.Backend.Set do
  @moduledoc """
  The bare skeleton of an event bus.

  An "event" is any data, it can be completely opaque.
  Subscribers provide functions to `subscribe/2`, which will be executed when an event is published.
  These functions are passed the event data.

  This module's event bus implementation is completely pure and unsynchronized across processes.
  The return values from `publish/2` and `subscribe/2` must be saved and passed into future calls.
  """

  defstruct [listeners: Map.new()]

  def new do
    {:ok, %__MODULE__{}}
  end

  defimpl Solvent.EventBus do
    def publish(%{listeners: listeners} = event_bus, data) do
      :ok = Enum.each(listeners, fn {id, listener} ->
        listener.(data)
      end)

      {:ok, event_bus}
    end

    require Logger
    def subscribe(event_bus, id, fun) do
      new_listeners = Map.put(event_bus.listeners, id, fun)

      {:ok, %{event_bus | listeners: new_listeners}}
    end

    def unsubscribe(%{listeners: listeners} = event_bus, id) do
      listeners = Map.delete(listeners, id)
      {:ok, %{event_bus | listeners: listeners}}
    end

    def get_listener(bus, id) do
      Map.fetch(bus.listeners, id)
    end
  end
end
