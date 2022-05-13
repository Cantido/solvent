defmodule Solvent.Backend.ProcessTest do
  use ExUnit.Case, async: true
  doctest Solvent.Backend.Process

  test "A process that subscribes to an event receives the event" do
    {:ok, bus} = Solvent.Backend.Process.new()
    test_pid = self()

    {:ok, bus} = Solvent.subscribe(bus, "ID 1", "event.published", fn event ->
      send(test_pid, event.data)
    end)

    test_ref = make_ref()
    {:ok, _} = Solvent.publish(bus, "event.published", test_ref)

    assert_receive ^test_ref
  end

  test "only notifies listenes with an equal type" do
    {:ok, bus} = Solvent.Backend.Process.new()
    test_pid = self()

    {:ok, bus} = Solvent.subscribe(bus, "ID 1", "event.published", fn _event ->
      send test_pid, :expected_handler
    end)
    {:ok, bus} = Solvent.subscribe(bus, "ID 2", "other.event.published", fn _event ->
      send test_pid, :other_handler
    end)

    {:ok, _} = Solvent.publish(bus, "event.published", :event_data)

    assert_receive :expected_handler
    refute_receive :other_handler
  end
end

