defmodule Solvent do
  @moduledoc """
  Documentation for `Solvent`.
  """

  def subscribe(bus, id, fun) do
    Solvent.EventBus.subscribe(bus, id, fun)
  end

  def publish(bus, data) do
    Solvent.EventBus.publish(bus, data)
  end
end
