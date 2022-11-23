defprotocol Solvent.Sink do
  @moduledoc """
  A protocol for delivering events to a target.

  By default, this protocol is implemented for:

  - `Tuple` - Interpreted as a `{module, function, args}` tuple

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
    send(pid, {:event, event})
  end
end
