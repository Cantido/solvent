# SPDX-FileCopyrightText: 2023 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Solvent.EventStore.ETSTest do
  use ExUnit.Case, async: true
  alias Solvent.EventStore.ETS, as: ETSStore
  alias Solvent.Event

  doctest Solvent.EventStore.ETS

  test "event can be fetched after insert" do
    event = Event.new("eventstoretest.fetch")
    handle = {event.source, event.id}
    sub_id = Uniq.UUID.uuid7()

    :ok = ETSStore.insert(event, [sub_id])

    {:ok, fetched_event} = ETSStore.fetch(handle)

    assert event.source == fetched_event.source
    assert event.id == fetched_event.id
  end

  test "event is not inserted if it has no subscribers" do
    event = Event.new("eventstoretest.fetch")
    handle = {event.source, event.id}

    :ok = ETSStore.insert(event, [])

    assert :error == ETSStore.fetch(handle)
  end

  test "event is deleted after all subscribers ack" do
    event = Event.new("eventstoretest.fetch")
    handle = {event.source, event.id}
    sub1 = Uniq.UUID.uuid7()
    sub2 = Uniq.UUID.uuid7()

    :ok = ETSStore.insert(event, [sub1, sub2])

    :ok = ETSStore.ack(handle, sub1)

    {:ok, _} = ETSStore.fetch(handle)

    :ok = ETSStore.ack(handle, sub2)

    assert :error == ETSStore.fetch(handle)
  end
end
