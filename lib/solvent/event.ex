defmodule Solvent.Event do
  @enforce_keys [:id, :source, :type]
  defstruct [
    id: nil,
    source: nil,
    type: nil,
    specversion: "1.0",
    data: nil
  ]
end
