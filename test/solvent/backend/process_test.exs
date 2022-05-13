defmodule Solvent.Backend.ProcessTest do
  use ExUnit.Case, async: true
  doctest Solvent.Backend.Process

  test "A process that subscribes to an event receives the event" do
    {:ok, bus} = Solvent.Backend.Process.new()
    test_pid = self()

    {:ok, bus} = Solvent.subscribe(bus, "ID 1", "event.published", fn data ->
      send(test_pid, data)
    end)

    test_ref = make_ref()
    {:ok, _} = Solvent.publish(bus, "event.published", test_ref)

    assert_receive ^test_ref
  end
end

