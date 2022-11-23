defmodule SolventTest do
  use ExUnit.Case
  doctest Solvent

  setup do
    Solvent.SubscriberStore.delete_all()
    Solvent.EventStore.delete_all()
  end

  test "calls subscriber mod-fun-args" do
    Solvent.subscribe(Uniq.UUID.uuid7(), [exact: [type: "subscribermfa.published"]], {Solvent.MessengerHandler, :handle_event, []})

    Solvent.publish("subscribermfa.published", data: self())

    assert_receive :notified
  end

  test "calls subscriber PIDs" do
    Solvent.subscribe(Uniq.UUID.uuid7(), [exact: [type: "subscriberpid.published"]], self())

    {:ok, {expected_source, expected_id}} = Solvent.publish("subscriberpid.published")

    assert_receive {:event, type, id}
    assert id == {expected_source, expected_id}
    assert type == "subscriberpid.published"
  end

  test "calls anonymous functions" do
    test_pid = self()
    test_ref = make_ref()

    Solvent.subscribe(Uniq.UUID.uuid7(), [exact: [type: "subscriberanon.published"]], fn _type, _id -> send test_pid, test_ref end)

    Solvent.publish("subscriberanon.published")

    assert_receive ^test_ref
  end

  test "can subscribe to sources without filters" do
    test_pid = self()

    sub = %Solvent.Subscription{
      id: Uniq.UUID.uuid7(),
      source: Uniq.UUID.uuid7(:urn),
      sink: test_pid
    }

    Solvent.subscribe(sub)
    {:ok, id} = Solvent.publish("subscriber.nofilter.published", source: sub.source)

    assert_receive {:event, _type, ^id}
  end

  test "can subscribe to types" do
    test_pid = self()

    sub = %Solvent.Subscription{
      id: Uniq.UUID.uuid7(),
      sink: test_pid,
      types: ["subscriber.type.published"]
    }

    Solvent.subscribe(sub)
    {:ok, id} = Solvent.publish("subscriber.type.published")

    assert_receive {:event, _type, ^id}
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
    filter = [any: [
      exact: [type: "multisubscribe.first"],
      exact: [type: "multisubscribe.second"]
    ]]

    Solvent.subscribe(Uniq.UUID.uuid7(), filter, {Solvent.MessengerHandler, :handle_event, []})

    Solvent.publish("multisubscribe.first", data: self())

    assert_receive :notified

    Solvent.publish("multisubscribe.second", data: self())

    assert_receive :notified
  end
end
