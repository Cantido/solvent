defmodule Solvent.MessengerHandler do
  use Solvent.Subscriber,
    id: "messenger subscriber",
    match_type: "event.published"

  def handle_event(event_id) do
    {:ok, event} = Solvent.EventStore.fetch(event_id)
    send(event.data, :notified)
  end
end
