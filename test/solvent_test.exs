defmodule SolventTest do
  use ExUnit.Case
  doctest Solvent

  setup do
    Solvent.SubscriberStore.delete_all()
    Solvent.EventStore.delete_all()
  end

  test "calls subscriber functions" do
    pid = self()
    ref = make_ref()

    Solvent.subscribe(Uniq.UUID.uuid7(), [exact: [type: "subscriberfun.published"]], fn _type, _event ->
      send(pid, ref)
    end)

    Solvent.publish("subscriberfun.published")

    assert_receive ^ref
    refute_receive ^ref
  end

  test "can subscribe modules" do
    Solvent.subscribe(Solvent.MessengerHandler, id: Uniq.UUID.uuid7())
    Solvent.publish("modulesubscribe.published", data: self())

    assert_receive :notified
  end

  test "can unsubscribe modules" do
    sub_id = Uniq.UUID.uuid7()
    Solvent.subscribe(Solvent.MessengerHandler, id: sub_id)
    Solvent.unsubscribe(sub_id)
    Solvent.publish("modulesubscribe.published", data: self())

    refute_receive :notified
  end

  test "modules auto-ack which deletes events" do
    Solvent.subscribe(Solvent.MessengerHandler, id: Uniq.UUID.uuid7())
    {:ok, event_id} = Solvent.publish("modulesubscribe.published", data: self())

    assert_receive :notified
    Process.sleep(100)
    assert :error == Solvent.EventStore.fetch(event_id)
  end

  test "can subscribe a function to multiple event types at once" do
    pid = self()
    filter = [any: [
      [exact: [type: "multisubscribe.first"]],
      [exact: [type: "multisubscribe.second"]]
    ]]

    Solvent.subscribe(Uniq.UUID.uuid7(), filter, fn
      "multisubscribe.first", _event -> send(pid, :notified_first)
      "multisubscribe.second", _event -> send(pid, :notified_second)
    end)

    Solvent.publish("multisubscribe.first")

    assert_receive :notified_first

    Solvent.publish("multisubscribe.second")

    assert_receive :notified_second
  end
end
