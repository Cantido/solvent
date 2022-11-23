defprotocol Solvent.Sink do
  @moduledoc """
  A protocol for delivering events to a target.

  By default, this protocol is implemented for:

  - `Tuple` - Interpreted as a `{module, function, args}` tuple. The function is called with the event type and ID given as the first and second argument.
  - `PID` - A message in the form of `{:event, event_type, event_id}` is sent to the PID.
  - `Function` - The function is called with the arguments `event_type` and `event_id`

  """

  def deliver(sink, event, protocol_settings \\ [])
end

defimpl Solvent.Sink, for: Tuple do
  def deliver({mod, fun, args}, event, _settings \\ []) do
    apply(mod, fun, [event.type, {event.source, event.id}] ++ args)
  end
end

defimpl Solvent.Sink, for: PID do
  def deliver(pid, event, _settings \\ []) do
    send(pid, {:event, event.type, {event.source, event.id}})
  end
end

defimpl Solvent.Sink, for: Function do
  def deliver(fun, event, _settings \\ []) do
    fun.(event.type, {event.source, event.id})
  end
end
