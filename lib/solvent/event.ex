defmodule Solvent.Event do
  @moduledoc """
  The event that subscribers are waiting for.

  Events in Solvent follow the [CloudEvents specification](https://github.com/cloudevents/spec),
  and the keys in this struct match the attribute names given in the spec.
  See `new/2` for valid values and their defaults.
  """

  @spec_string_keys [
    "id",
    "source",
    "type",
    "specversion",
    "data",
    "datacontenttype",
    "dataschema",
    "subject",
    "time"
  ]

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
      id: Uniq.UUID.uuid7(),
      source: "Solvent",
      type: type,
      time: DateTime.utc_now()
    }
    |> struct!(opts)
  end

  @doc """
  Encodes an event as JSON according to the [JSON Event Format for CloudEvents](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/formats/json-format.md).

  If an event struct does not have a defined `:datacontenttype` key, then it will be set to `application/json`,
  and the data will be encoded with the rest of the struct.
  If you're using your own struct as the data in this case, you can implement `Jason.Encoder` to customize how your data gets serialized.

  If the event struct _does_ have a defined `:datacontenttype`, then the encoder behaves according to the [Payload Serialization](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/formats/json-format.md#311-payload-serialization) spec.
  That means we check these three conditions, in order:
  1. If event data is binary, encode it with base-64, then save it as the `:data_base64` value
  2. If `:datacontenttype` matches `application/json`, then it is encoded inline as JSON with the rest of the struct, as `:data`.
     Make sure your data implements `Jason.Encoder` if you expect to fall into this case.
  3. The `to_string/1` function is used on the value, and it is stored in `:data`.
     Make sure your data implements `String.Chars` if you expect to fall into this case.
  """
  def to_json!(event) do
    Jason.encode!(event)
  end

  @doc """
  Decodes a JSON-encoded CloudEvent.
  """
  def from_json(event_json) do
    with {:ok, event_map} <- Jason.decode(event_json),
         {:ok, event_map} <- encode_data(event_map),
         {:ok, event_map} <- nest_extensions(event_map),
         event_map = keys_to_atoms(event_map),
         {:ok, event_map} <- decode_time(event_map) do
      {:ok, struct!(__MODULE__, event_map)}
    end
  end

  defp encode_data(event_map) do
    event_map =
      if Map.has_key?(event_map, "data_base64") do
        event_map
        |> Map.delete("data_base64")
        |> Map.put("data", Base.decode64!(event_map["data_base64"]))
      else
        event_map
      end
    {:ok, event_map}
  end

  defp nest_extensions(event_map) do
    extension_map =
      Map.drop(event_map, @spec_string_keys)

    spec_map =
      Map.take(event_map, @spec_string_keys)
      |> Map.put("extensions", extension_map)

    {:ok, spec_map}
  end

  defp keys_to_atoms(map) do
    Map.new(map, fn {key, val} ->
      {String.to_existing_atom(key), val}
    end)
  end

  defp decode_time(event_map) do
    if Map.has_key?(event_map, :time) do
      case DateTime.from_iso8601(event_map[:time]) do
        {:ok, time, _offset} -> {:ok, Map.put(event_map, :time, time)}
        err -> err
      end
    else
        {:ok, event_map}
    end
  end

  defimpl Jason.Encoder do
    def encode(struct, opts) do
      event =
        Map.from_struct(struct)

      event =
        if is_nil(event.datacontenttype) do
          Map.put(event, :datacontenttype, "application/json")
        else
          event
        end

      {extensions, event} = Map.pop(event, :extensions)

      # merging the event as the second argument so that it takes precedence
      event = Map.merge(extensions, event)

      event =
        cond do
          is_binary(event.data) ->
            event
            |> Map.put(:data_base64, Base.encode64(event.data))
            |> Map.delete(:data)
          is_json?(event.datacontenttype) ->
            # skip, since we'll just decode the entire thing into JSON
            event
          true ->
            Map.update!(event, :data, &to_string/1)
        end

      event =
        Enum.reject(event, fn {_key, val} ->
          is_nil(val)
        end)
        |> Map.new()

      Jason.Encode.map(event, opts)
    end

    defp is_json?(content_type) do
      String.valid?(content_type) and (String.ends_with?(content_type, "/json") or String.ends_with?(content_type, "+json"))
    end
  end
end
