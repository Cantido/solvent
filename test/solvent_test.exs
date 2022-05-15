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

  test "can subscribe modules" do
    Solvent.subscribe(Solvent.MessengerHandler, id: UUID.uuid4())
    Solvent.publish("event.published", data: self())

    assert_receive :notified
  end
end
