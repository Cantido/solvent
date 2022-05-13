defmodule Solvent do
  @moduledoc """
  Documentation for `Solvent`.
  """

  def subscribe(bus, fun) do
    Solvent.EventBus.subscribe(bus, fun)
  end

  def publish(bus, data) do
    Solvent.EventBus.publish(bus, data)
  end
end
