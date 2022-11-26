defmodule SolventTest do
  use ExUnit.Case
  doctest Solvent

  setup do
    Solvent.SubscriberStore.delete_all()
    Solvent.EventStore.delete_all()
  end

  test "calls subscriber mod-fun-args" do
    Solvent.subscribe({Solvent.MessengerHandler, :handle_event, []}, types: ["subscribermfa.published"])

    test_ref = make_ref()
    Solvent.publish("subscribermfa.published", data: {self(), test_ref})

    assert_receive ^test_ref
  end

  test "calls subscriber PIDs" do
    Solvent.subscribe(self(), types: ["subscriberpid.published"])

    {:ok, {expected_source, expected_id}} = Solvent.publish("subscriberpid.published")

    assert_receive {:event, type, id}
    assert id == {expected_source, expected_id}
    assert type == "subscriberpid.published"
  end

  test "calls anonymous functions" do
    test_pid = self()
    test_ref = make_ref()

    Solvent.subscribe(fn _type, _id -> send test_pid, test_ref end, types: ["subscriberanon.published"])

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

  test "can subscribe modules that select with filters" do
    test_ref = make_ref()
    Solvent.subscribe(Solvent.MessengerHandler, id: Uniq.UUID.uuid7())
    Solvent.publish("modulesubscribe.published", data: {self(), test_ref})

    assert_receive ^test_ref
  end

  test "can subscribe modules that select with sources" do
    test_ref = make_ref()
    Solvent.subscribe(Solvent.SourceHandler, id: Uniq.UUID.uuid7())
    Solvent.publish("sourcemodulesubscribe.published", source: "subscriber-module-source", data: {self(), test_ref})

    assert_receive ^test_ref
  end

  test "can subscribe modules that select with types" do
    test_ref = make_ref()
    Solvent.subscribe(Solvent.TypeHandler, id: Uniq.UUID.uuid7())
    Solvent.publish("typemodulesubscribe.published", data: {self(), test_ref})

    assert_receive ^test_ref
  end

  test "can unsubscribe modules" do
    test_ref = make_ref()
    sub_id = Uniq.UUID.uuid7()
    Solvent.subscribe(Solvent.MessengerHandler, id: sub_id)
    Solvent.unsubscribe(sub_id)
    Solvent.publish("modulesubscribe.published", data: {self(), test_ref})

    refute_receive ^test_ref
  end

  test "modules auto-ack which deletes events" do
    test_ref = make_ref()
    Solvent.subscribe(Solvent.MessengerHandler, id: Uniq.UUID.uuid7())
    {:ok, event_id} = Solvent.publish("modulesubscribe.published", data: {self(), test_ref})

    assert_receive ^test_ref
    Process.sleep(100)
    assert :error == Solvent.EventStore.fetch(event_id)
  end

  test "can subscribe a function to multiple event types at once" do
    test_ref = make_ref()
    filter = [any: [
      exact: [type: "multisubscribe.first"],
      exact: [type: "multisubscribe.second"]
    ]]

    Solvent.subscribe(Uniq.UUID.uuid7(), filter, {Solvent.MessengerHandler, :handle_event, []})

    Solvent.publish("multisubscribe.first", data: {self(), test_ref})

    assert_receive ^test_ref

    Solvent.publish("multisubscribe.second", data: {self(), test_ref})

    assert_receive ^test_ref
  end
end
