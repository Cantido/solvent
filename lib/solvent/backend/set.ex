defmodule Solvent.Backend.Set do
  @moduledoc """
  The bare skeleton of an event bus.

  This module's event bus implementation is completely pure and unsynchronized across processes.
  The return values from `publish/2` and `subscribe/2` must be saved and passed into future calls.
  """
  defstruct [set: MapSet.new()]

  def new do
    {:ok, %__MODULE__{}}
  end

  defimpl Solvent.EventBus do
    def publish(%{set: set} = event_bus, data) do
      :ok = Enum.each(set, fn fun ->
        fun.(data)
      end)
      {:ok, event_bus}
    end

    def subscribe(%{set: set} = event_bus, fun) do
      set = MapSet.put(set, fun)
      {:ok, %{event_bus | set: set}}
    end
  end
end
