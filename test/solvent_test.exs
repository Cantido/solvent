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

    Solvent.subscribe(UUID.uuid4(), "subscriberfun.published", fn _type, _event ->
      send(pid, ref)
    end)

    Solvent.publish("subscriberfun.published")

    assert_receive ^ref
    refute_receive ^ref
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

  test "modules auto-ack which deletes events" do
    Solvent.subscribe(Solvent.MessengerHandler, id: UUID.uuid4())
    {:ok, event_id} = Solvent.publish("modulesubscribe.published", data: self())

    assert_receive :notified
    Process.sleep(100)
    assert :error == Solvent.EventStore.fetch(event_id)
  end

  test "can subscribe a function to multiple event types at once" do
    pid = self()
    subscriptions = [
      "multisubscribe.first",
      "multisubscribe.second"
    ]

    Solvent.subscribe(UUID.uuid4(), subscriptions, fn
      "multisubscribe.first", _event -> send(pid, :notified_first)
      "multisubscribe.second", _event -> send(pid, :notified_second)
    end)

    Solvent.publish("multisubscribe.first")

    assert_receive :notified_first

    Solvent.publish("multisubscribe.second")

    assert_receive :notified_second
  end

  test "can subscribe to :all" do
    pid = self()

    Solvent.subscribe(UUID.uuid4(), :all, fn _type, _event ->
      send(pid, :subscribed_to_all)
    end)

    Solvent.publish("subscribetoall.published")

    assert_receive :subscribed_to_all
  end
end
