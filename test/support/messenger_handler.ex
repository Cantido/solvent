defmodule Solvent.MessengerHandler do
  @moduledoc """
  A module subscriber that subscribes to the type `"modulesubscribe.published"` and
  expects a `{pid, ref}` tuple in the event's data, to which it will send the ref back.
  """
  use Solvent.Subscriber,
    id: "messenger subscriber",
    filters: [exact: [type: "modulesubscribe.published"]]

  require Logger

  def handle_event(type, event_id, _listener_id) do
    Logger.debug("Module handler invoked with event ID #{inspect(event_id)} with type #{type}")

    case Solvent.EventStore.fetch(event_id) do
      {:ok, event} ->
        {pid, ref} = event.data
        send(pid, ref)

      :error ->
        raise "Event not found"
    end

    :ok
  end
end
