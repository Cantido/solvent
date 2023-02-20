defmodule Solvent.EventStore.ETSTest do
  use ExUnit.Case, async: true
  alias Solvent.EventStore.ETS, as: ETSStore
  alias Solvent.Event
  import Solvent.EventFixtures
  import Solvent.SubscriberFixtures

  doctest Solvent.EventStore.ETS

  test "event can be fetched after insert" do
    event = Event.new("eventstoretest.fetch")
    handle = {event.source, event.id}
    sub_id = subscriber_id()

    :ok = ETSStore.insert(event, [sub_id])

    {:ok, fetched_event} = ETSStore.fetch(handle)

    assert event.source == fetched_event.source
    assert event.id == fetched_event.id
  end

  test "event is deleted after all subscribers ack" do
    event = Event.new("eventstoretest.fetch")
    handle = {event.source, event.id}
    sub1 = subscriber_id()
    sub2 = subscriber_id()

    :ok = ETSStore.insert(event, [sub1, sub2])

    :ok = ETSStore.ack(handle, sub1)

    {:ok, _} = ETSStore.fetch(handle)

    :ok = ETSStore.ack(handle, sub2)

    assert :error == ETSStore.fetch(handle)
  end
end
