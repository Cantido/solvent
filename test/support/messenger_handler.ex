defmodule Solvent.MessengerHandler do
  use Solvent.Subscriber,
    id: "messenger subscriber",
    filter: [exact: [type: "modulesubscribe.published"]]

  require Logger

  def handle_event(type, event_id) do
    Logger.debug("Module handler invoked with event ID #{inspect(event_id)} with type #{type}")

    case Solvent.EventStore.fetch(event_id) do
      {:ok, event} ->
        send(event.data, :notified)
      :error ->
        nil
    end

    :ok
  end
end
