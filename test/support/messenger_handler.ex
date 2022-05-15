defmodule Solvent.MessengerHandler do
  use Solvent.Subscriber,
    id: "messenger subscriber",
    match_type: ~r/modulesubscribe\..*/
  require Logger

  def handle_event(event_id) do
    Logger.debug("Module handler invoked with event ID #{inspect event_id}")
    {:ok, event} = Solvent.EventStore.fetch(event_id)
    send(event.data, :notified)
  end
end
