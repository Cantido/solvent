defmodule Solvent.TypeHandler do
  use Solvent.Subscriber,
    id: "messenger subscriber",
    types: ["typemodulesubscribe.published"]

  require Logger

  def handle_event(type, event_id, _listener_id) do
    Logger.debug("Module handler invoked with event ID #{inspect(event_id)} with type #{type}")

    case Solvent.EventStore.fetch(event_id) do
      {:ok, event} ->
        {pid, ref} = event.data
        send(pid, ref)
      :error ->
        nil
    end

    :ok
  end
end
