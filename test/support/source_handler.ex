# SPDX-FileCopyrightText: 2023 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Solvent.SourceHandler do
  @moduledoc """
  A module subscriber that handles all events with the source `"subscriber-module-source"`.
  """
  use Solvent.Subscriber,
    id: "source subscriber",
    source: "subscriber-module-source"

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
