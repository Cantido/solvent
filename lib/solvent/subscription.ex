defmodule Solvent.Subscription do
  @moduledoc """
  Describes a consumer's wish to receive events, as well as how to deliver them.

  See `new/2` for instructions on how to create one of these structs,
  and then give that struct to `Solvent.subscribe/1` to being receiving events.
  """

  alias Solvent.Filter

  @type id :: String.t()

  @enforce_keys [:id, :sink]
  defstruct [
    :id,
    :sink,
    :source,
    filters: [],
    types: [],
    config: []
  ]

  @doc """
  Create a new subscription struct.

  This function does not subscribe to the event stream,
  but once you create a `Solvent.Subscription` struct, you can give it to `Solvent.subscribe/1` to subscribe to events.

  After providing a sink, you can additionally match for a source, multiple types, or provide filters to further match events.

  ## Examples

  To create a subscription for matching all events passing through Solvent, just provide a sink.

      iex> Solvent.Subscription.new({MyModule, :handle_event, []})

  To match all events coming from a single source, provide a `:source` option.
  It should be a string.

      iex> Solvent.Subscription.new({MyModule, :handle_event, []}, source: "https://myapp.example.com")

  You can also match a set of event types.

      iex> Solvent.Subscription.new({MyModule, :handle_event, []}, types: ["com.example.message.sent", "com.example.message.received"])

  For more complex filtering, provide a struct implementing `Solvent.Filter`.
  You can build one from a keyword list with `Solvent.build_filters/1`.

      iex> Solvent.Subscription.new({MyModule, :handle_event, []}, filter: Solvent.build_filters([prefix: [type: "com.example."]]))

  Multiple options can be provided in the same subscription.

      iex> Solvent.Subscription.new(
        {MyModule, :handle_event, []},
        source: "https://myapp.example.com",
        types: ["com.example.message.sent", "com.example.message.received"]
      )


  ## Additional configuration

  You can also configure your subscription with the `:config` key, which accepts a keyword list.

  - `:auto_ack` - Tell Solvent to automatically acknoledge the event once it is done delivering the event to the sink.
    Do not set this to `true` if you pass off the event ID to be fetched by another process.
  """
  def new(sink, opts \\ []) do
    id = Keyword.get(opts, :id, Uniq.UUID.uuid7())
    source = Keyword.get(opts, :source)
    types = Keyword.get(opts, :types, [])
    filters = Keyword.get(opts, :filters, [])
    config = Keyword.get(opts, :config, [])

    validate_id(id)
    validate_sink(sink)
    validate_filters(filters)
    validate_source(source)
    validate_types(types)

    %__MODULE__{
      id: id,
      sink: sink,
      source: source,
      types: types,
      filters: filters,
      config: config
    }
  end

  defp validate_id(id) do
    unless String.valid?(id) and String.length(id) > 0 do
      raise ArgumentError,
            "The `id` option must be a valid and nonempty string. Got: #{inspect(id)}"
    end
  end

  defp validate_sink(sink) do
    if is_nil(Solvent.Sink.impl_for(sink)) do
      raise ArgumentError,
            "The `sink` argument must implement `Solvent.Sink`. Got: #{inspect(sink)}"
    end
  end

  defp validate_filters(filters) do
    unless is_nil(filters) or Enum.all?(filters, &Solvent.Filter.impl_for/1) do
      raise ArgumentError,
            "The members of the `filters` argument list must implement `Solvent.Filter`. Got: #{inspect(filters)}"
    end
  end

  defp validate_source(source) do
    unless is_nil(source) or (String.valid?(source) and String.length(source) > 0) do
      raise ArgumentError,
            "The `source` argument must be either nil or a non-empty string. Got: #{inspect(source)}"
    end
  end

  defp validate_types(types) do
    unless is_nil(types) or Enum.all?(types, &(String.length(&1) > 0)) do
      raise ArgumentError,
            "The members of the `types` argument list must be non-empty strings. Got: #{inspect(types)}"
    end
  end

  @doc """
  Test if a subscription should deliver a certain event.
  """
  def match?(subscription, event) do
    source_match?(subscription.source, event) and
      filter_match?(subscription.filters, event) and
      types_match?(subscription.types, event)
  end

  defp source_match?(nil, _event), do: true
  defp source_match?(source, event), do: source == event.source

  defp types_match?(nil, _event), do: true
  defp types_match?([], _event), do: true
  defp types_match?(types, event), do: event.type in types

  defp filter_match?(nil, _event), do: true
  defp filter_match?([], _event), do: true
  defp filter_match?(filters, event), do: Enum.all?(filters, &Filter.match?(&1, event))
end
