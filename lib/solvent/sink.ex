defprotocol Solvent.Sink do
  @moduledoc """
  A protocol for delivering events to a target.

  By default, this protocol is implemented for:

  - `Tuple` - Interpreted as a `{module, function, args}` tuple.
    The function is called with the event type, event handle, and subscriber ID given as the first, second, and third arguments.
  - `PID` - A message in the form of `{:event, event_type, event_handle, subscriber_id}` is sent to the PID.
  - `Function` - The function is called with the event type, event handle, and subscriber ID as the first, second, and third arguments.

  """

  def deliver(sink, event, listener_id, protocol_settings \\ [])
end

defimpl Solvent.Sink, for: Tuple do
  def deliver({mod, fun, args}, event, listener_id, _settings \\ []) do
    apply(mod, fun, [event.type, {event.source, event.id}, listener_id] ++ args)
  end
end

defimpl Solvent.Sink, for: PID do
  def deliver(pid, event, listener_id, _settings \\ []) do
    send(pid, {:event, event.type, {event.source, event.id}, listener_id})
  end
end

defimpl Solvent.Sink, for: Function do
  def deliver(fun, event, listener_id, _settings \\ []) do
    fun.(event.type, {event.source, event.id}, listener_id)
  end
end
