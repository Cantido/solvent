# SPDX-FileCopyrightText: 2023 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Solvent.Event do
  @moduledoc """
  The event that subscribers are waiting for.

  Events in Solvent follow the [CloudEvents specification](https://github.com/cloudevents/spec),
  and the keys in this struct match the attribute names given in the spec.
  See `new/2` for valid values and their defaults.
  """

  @type t :: Cloudevents.Format.V_1_0.Event.t()
  @type id :: String.t()
  @type source :: String.t()
  @type type :: String.t()
  @type handle :: {source(), id()}
  @type property_key ::
          :specversion
          | :id
          | :source
          | :type
          | :time
          | :subject
          | :data
          | :datacontenttype
          | :dataschema
          | String.t()
  @type property_value :: any()
  @type new_option ::
          {:specversion, String.t()}
          | {:source, source()}
          | {:time, DateTime.t()}
          | {:subject, String.t()}
          | {:data, any()}
          | {:datacontenttype, String.t()}
          | {:dataschema, String.t()}
  @type new_options :: [new_option()]

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
  @spec new(type(), new_options()) :: t()
  def new(type, opts \\ []) do
    %{
      specversion: "1.0",
      id: Uniq.UUID.uuid7(),
      source: "Solvent",
      type: type,
      time: DateTime.utc_now()
    }
    |> Map.merge(Map.new(opts))
    |> Cloudevents.from_map!()
  end
end
