defmodule Solvent.Backend.ProcessTest do
  use ExUnit.Case, async: true
  doctest Solvent.Backend.Process

  test "A process that subscribes to an event receives the event" do
    {:ok, bus_pid} = Solvent.Backend.Process.start_link()
    bus = %Solvent.Backend.Process{pid: bus_pid}
    test_pid = self()

    {:ok, _} = Solvent.subscribe(bus, fn ref ->
      send(test_pid, ref)
    end)

    test_ref = make_ref()
    {:ok, _} = Solvent.publish(bus, test_ref)

    assert_receive ^test_ref
  end
end

