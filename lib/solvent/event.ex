defmodule Solvent.Event do
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
