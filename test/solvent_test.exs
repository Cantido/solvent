defmodule SolventTest do
  use ExUnit.Case
  doctest Solvent

  test "calls subscriber functions" do
    pid = self()
    Solvent.subscribe(UUID.uuid4(), "event.published", fn _event ->
      send(pid, :notified)
    end)

    Solvent.publish("event.published")

    assert_receive :notified
  end
end
