defmodule SolventTest do
  use ExUnit.Case
  doctest Solvent

  setup do
    :ets.delete_all_objects(:solvent_listeners)
    Solvent.EventStore.delete_all()
  end

  test "calls subscriber functions" do
    pid = self()
    Solvent.subscribe(UUID.uuid4(), "subscriberfun.published", fn _event ->
      send(pid, :notified)
    end)

    Solvent.publish("subscriberfun.published")

    assert_receive :notified
  end

  test "can subscribe modules" do
    Solvent.subscribe(Solvent.MessengerHandler, id: UUID.uuid4())
    Solvent.publish("modulesubscribe.published", data: self())

    assert_receive :notified
  end

  test "can unsubscribe modules" do
    sub_id = UUID.uuid4()
    Solvent.subscribe(Solvent.MessengerHandler, id: sub_id)
    Solvent.unsubscribe(sub_id)
    Solvent.publish("modulesubscribe.published", data: self())

    refute_receive :notified
  end
end
