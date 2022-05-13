defmodule Solvent.Backend.SetTest do
  use ExUnit.Case, async: true
  doctest Solvent.Backend.Set
  require Logger

  test "A process that subscribes to an event receives the event" do
    {:ok, bus} = Solvent.Backend.Set.new()
    test_pid = self()

    {:ok, bus} = Solvent.subscribe(bus, "ID 1", fn data ->
      send(test_pid, data)
    end)

    test_ref = make_ref()
    {:ok, _} = Solvent.publish(bus, test_ref)

    assert_receive ^test_ref
  end
end

