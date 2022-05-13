defmodule Solvent do
  @moduledoc """
  Documentation for `Solvent`.
  """

  def subscribe(bus, id, match_type, fun) do
    Solvent.EventBus.subscribe(bus, id, match_type, fun)
  end

  def publish(bus, type, data) do
    Solvent.EventBus.publish(bus, type, data)
  end
end
