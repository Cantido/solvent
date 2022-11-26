defmodule Solvent.SourceHandler do
  use Solvent.Subscriber,
    id: "source subscriber",
    source: "subscriber-module-source"


  require Logger

  def handle_event(type, event_id) do
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
