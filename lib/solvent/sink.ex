# SPDX-FileCopyrightText: 2023 Rosa Richter
#
# SPDX-License-Identifier: MIT

defprotocol Solvent.Sink do
  @moduledoc """
  A protocol for delivering events to a target.

  By default, this protocol is implemented for:

  - `Tuple` - Interpreted as a `{module, function, args}` tuple.
    The function is called with the event type, event handle, and subscription ID given as the first, second, and third arguments.
  - `PID` - A message in the form of `{:event, event_type, event_handle, subscription_id}` is sent to the PID.
  - `Function` - The function is called with the event type, event handle, and subscription ID as the first, second, and third arguments.

  """

  @doc """
  Send an event to a sink.
  The subscription ID is also required so that the recipient can acknowledge the event.

  Options are accepted to configure details of the delivery.
  """
  @spec deliver(Solvent.Sink.t(), Solvent.Event.t(), String.t(), keyword()) :: any()
  def deliver(sink, event, subscription_id, protocol_settings \\ [])
end

defimpl Solvent.Sink, for: Tuple do
  def deliver({mod, fun, args}, event, subscription_id, _settings \\ []) do
    apply(mod, fun, [event.type, {event.source, event.id}, subscription_id] ++ args)
  end
end

defimpl Solvent.Sink, for: PID do
  def deliver(pid, event, subscription_id, _settings \\ []) do
    send(pid, {:event, event.type, {event.source, event.id}, subscription_id})
  end
end

defimpl Solvent.Sink, for: Function do
  def deliver(fun, event, subscription_id, _settings \\ []) do
    fun.(event.type, {event.source, event.id}, subscription_id)
  end
end
