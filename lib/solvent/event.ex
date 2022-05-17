defmodule Solvent.Event do
  @moduledoc """
  The event that subscribers are waiting for.

  Events in Solvent follow the [CloudEvents specification](https://github.com/cloudevents/spec),
  and the keys in this struct match the attribute names given in the spec.
  See `new/2` for valid values and their defaults.
  """
  @enforce_keys [:id, :source, :type]
  defstruct id: nil,
            source: nil,
            type: nil,
            specversion: "1.0",
            data: nil,
            datacontenttype: nil,
            dataschema: nil,
            subject: nil,
            time: nil,
            extensions: %{}

  @doc """
  Create a new event.

  Override default values by providing them in `opts`.

  ## Options

    - `:id` - the event's unique identifier. Default: a new version 4 UUID.
    - `:source` - the entity that created this event. Default: `"Solvent"`.
    - `:type` - also known as a topic, this is the name of the event that occurred.
      Set by the first argument to this function, but can be overridden.
    - `:data` - information associated with the event. Default: `nil`
    - `:datacontenttype` - a MIME type for the data in `:data`. Default: `nil`
    - `:dataschema` - details on the structure of the value in `:data`. Default: `nil`
    - `:subject` - describes the subject of the event, for example a filename for binary data in `:data`. Default: `nil`
    - `:time` - a timestamp for when the event occurred. Default: `DateTime.utc_now()` at struct creation time.
    - `:extensions` - a map of additional properties. Default: `%{}`
  """
  def new(type, opts \\ []) do
    %__MODULE__{
      id: UUID.uuid4(),
      source: "Solvent",
      type: type,
      time: DateTime.utc_now()
    }
    |> struct!(opts)
  end
end
