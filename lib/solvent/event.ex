defmodule Solvent.Event do
  @moduledoc """
  The event that subscribers are waiting for.

  Events in Solvent follow the [CloudEvents specification](https://github.com/cloudevents/spec),
  and the keys in this struct match the attribute names given in the spec.
  """
  @enforce_keys [:id, :source, :type]
  defstruct [
    id: nil,
    source: nil,
    type: nil,
    specversion: "1.0",
    data: nil,
    datacontenttype: nil,
    dataschema: nil,
    subject: nil,
    time: nil,
    extensions: %{}
  ]
end
