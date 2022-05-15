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

  test "modules auto-delete events by default" do
    event_id = UUID.uuid4()
    Solvent.subscribe(Solvent.MessengerHandler, id: UUID.uuid4())
    Solvent.publish("deletedevent.published", id: event_id, data: self())

    assert_receive :notified

    assert :error == Solvent.EventStore.fetch(event_id)
  end
end
