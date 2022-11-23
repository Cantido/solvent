defmodule Solvent do
  use TelemetryRegistry

  telemetry_event %{
    event: [:solvent, :event, :published],
    description: "Emitted when an event is published",
    measurements: "%{}",
    metadata: "%{event_source: String.t(), event_id: String.t(), event_type: String.t(), subscriber_count: non_neg_integer()}"
  }

  telemetry_event %{
    event: [:solvent, :subscriber, :processing, :start],
    description: "Emitted when a subscriber begins processing an event",
    measurements: "%{}",
    metadata: "%{subscriber_id: String.t(), event_source: String.t(), event_id: String.t(), event_type: String.t()}"
  }

  telemetry_event %{
    event: [:solvent, :subscriber, :processing, :stop],
    description: "Emitted when a subscriber finishes processing an event",
    measurements: "%{duration: non_neg_integer()}",
    metadata: "%{subscriber_id: String.t(), event_source: String.t(), event_id: String.t(), event_type: String.t()}"
  }

  telemetry_event %{
    event: [:solvent, :subscriber, :subscribing, :start],
    description: "Emitted when a subscriber begins subscribing to the event stream",
    measurements: "%{}",
    metadata: "%{subscriber_id: String.t(), filter: String.t()}"
  }

  telemetry_event %{
    event: [:solvent, :subscriber, :subscribing, :stop],
    description: "Emitted when a subscriber is finished subscribing to the event stream",
    measurements: "%{duration: non_neg_integer()}",
    metadata: "%{subscriber_id: String.t(), filter: String.t()}"
  }

  @moduledoc """
  Solvent is an event bus built to be fast and easy-to-use.

  Publish and subscribe to events here.
  You can either provide a module-function-args tuple to be run, with `subscribe/2` and `subscribe/3`,
  or subscribe a module using `subscribe/1`.
  See the docs for `Solvent.Subscriber` for more information on module subscribers.

      iex> Solvent.subscribe(
      ...>  "My first subscriber",
      ...>  [exact: [type: "com.example.event.published"]],
      ...>  {Solvent.MessengerHandler, :handle_event, []}
      ...> )
      {:ok, "My first subscriber"}

  It's important to observe that subscriber functions are given the _identifier_ of an event, _not_ the event itself.
  Also, note that we call `Solvent.EventStore.ack/2` once we're done with the event,
  so that Solvent knows it can clean up the event from the store.

  > #### Tip {: .tip}
  >
  > Use the `Solvent.Subscriber` module to make a subscriber that automatically acknowledges events,
  > along with lots of other nice features.

  The `filter` argument must be a filter expression. See `Loom.Filter` for documentation on filter expressions.

  Once you have a subscriber, publish an event.
  Data is optional, only a type is required.
  This can be any string.
  I would recommend the CloudEvents format, which starts with a reversed DNS name, and is dot-separated.
  This will help avoid collisions with events from other applications.

      Solvent.publish("io.github.cantido.myevent.published")
      {:ok, "0b06bdb7-06a7-4df9-a825-1fd225ceea43"}

  Here you can also supply data for the event with the `:data` option.

      Solvent.publish("io.github.cantido.myevent.published", data: "Hello, world!")
      {:ok, "d0f63676-b853-4f30-8bcf-ea10f2184556"}

  This will be available on the `:data` key of the event object you fetch from `Solvent.EventStore`.
  See the `Solvent.Event` docs for more information on what that struct contains.

  ## Telemetry

  #{telemetry_docs()}

  """

  alias Solvent.Subscription

  require Logger


  @doc """
  Execute a module subscriber when an event is published.

  When the first argument is a module, the module is subscribed to the event bus,
  and the second argument is expected to be a list of options, if it is provided at all.
  See `Solvent.Subscriber` for details.

  If the first argument is a string or regex, then the second argument must be a module-function-args tuple.
  Besides that, this function behaves exactly like `subscribe/3` but with an auto-generated ID.
  """
  def subscribe(arg1, arg2 \\ [])

  def subscribe(module, opts) when is_atom(module) and is_list(opts) do
    id = Keyword.get(opts, :id, apply(module, :subscriber_id, []))
    filter = Keyword.get(opts, :filter, apply(module, :filter, []))
    auto_ack? = Keyword.get(opts, :auto_ack, apply(module, :auto_ack?, []))

    mfa = {Solvent.Subscriber, :run_module, [module, id, auto_ack?]}

    subscribe(id, filter, mfa)
  end

  def subscribe(filter, fun) when is_tuple(fun) do
    subscribe(Uniq.UUID.uuid7(), filter, fun)
  end

  @doc """
  Execute a function when an event is published.

  The `filter` argument is a keyword list of Cloudevents filters.

  The function argument will be given the ID of the event.
  You must fetch the event from `Solvent.EventStore` if you wish to use it.

  The ID is optional, and defaults to a version 7 UUID.

      iex> Solvent.subscribe(
      ...>   "My subscriber",
      ...>   [exact: [type: "subscriber.event.published"]],
      ...>   {Solvent.MessengerHandler, :handle_event, []}
      ...> )
      {:ok, "My subscriber"}

  The second argument, `filter`, must be a filter expression (see `Solvent.Filter`) or a struct that implements `Solvent.Filter`.
  """
  def subscribe(id, filter, fun) when is_tuple(fun) do
    filter =
      if is_list(filter) do
        build_filter(filter)
      else
        filter
      end

    if is_nil(Solvent.Filter.impl_for(filter)) do
      raise ArgumentError, "Argument must be either a filter expression or must implement `Solvent.Filter`. Got: #{inspect filter}"
    end

    :telemetry.span(
      [:solvent, :subscriber, :subscribing],
      %{subscriber_id: id, filter: filter},
      fn ->
        subscription = %Subscription{
          id: id,
          filter: filter,
          sink: fun
        }
        :ok = Solvent.SubscriberStore.insert(subscription)
        {:ok, %{}}
      end
    )

    {:ok, id}
  end

  @doc """
  Remove a subscriber.
  """
  def unsubscribe(id) do
    Solvent.SubscriberStore.delete(id)
  end

  @doc """
  Publish an event to the event bus, triggering all subscriber functions.

  Only a type (AKA "topic") is required.
  All other fields can be supplied using the options.
  See `Solvent.Event` for details on what that struct contains.
  All values given as options are inserted into the event struct.

  ID values are version 7 UUIDs by default, and you don't need to provide them.
  ## Examples

      Solvent.publish("io.github.cantido.documentation.read")
      {:ok, "some-random-uuid"}

      iex> Solvent.publish(
      ...>   "io.github.cantido.documentation.read",
      ...>   id: "read-docs-id",
      ...>   source: "myapp",
      ...>   datacontenttype: "application/json",
      ...>   data: ~s({"hello":"world"})
      ...> )
      {:ok, {"myapp", "read-docs-id"}}

  You can also build an event yourself with `Solvent.Event.new/1` and publish it with this function.
  """
  def publish(event, opts \\ [])

  def publish(type, opts) when is_binary(type) do
    event = Solvent.Event.new(type, opts)
    publish(event, opts)
  end

  def publish(event, _opts) do
    Task.Supervisor.start_child(Solvent.TaskSupervisor, fn ->
      subscribers = Solvent.SubscriberStore.listeners_for(event)
      subscriber_ids = Enum.map(subscribers, &elem(&1, 1)) |> Enum.uniq()

      Logger.debug("Publishing event #{event.id}, (#{event.type}). Subscribers are: #{inspect subscriber_ids, pretty: true}")

      :telemetry.execute(
        [:solvent, :event, :published],
        %{},
        %{event_source: event.source, event_id: event.id, event_type: event.type, subscriber_count: Enum.count(subscribers)}
      )

      if Enum.count(subscribers) > 0 do
          :ok = Solvent.EventStore.insert(event, subscriber_ids)

        notifier_fun = fn {subscriber_id, subscription} ->
          {mod, fun, args} = subscription.sink
          Task.Supervisor.start_child(Solvent.TaskSupervisor, fn ->
            :telemetry.span(
              [:solvent, :subscriber, :processing],
              %{subscriber_id: subscriber_id, event_source: event.source, event_id: event.id, event_type: event.type},
              fn ->
                Logger.metadata(
                  solvent_subscriber_id: subscriber_id,
                  solvent_event_source: event.source,
                  solvent_event_id: event.id,
                  solvent_event_type: event.type
                )
                apply(mod, fun, [event.type, {event.source, event.id}] ++ args)
                {:ok, %{}}
              end
            )

            :ok
          end)
        end

        Task.Supervisor.async_stream(Solvent.TaskSupervisor, subscribers, notifier_fun,
          timeout: :infinity
        )
        |> Stream.run()
      else
        Logger.warn("No subscribers matched event type #{event.type}. Solvent will not insert the event into the event store.")
      end
    end)

    {:ok, {event.source, event.id}}
  end

  def build_filter([exact: props]), do: %Solvent.Filter.Exact{properties: props}
  def build_filter([prefix: props]), do: %Solvent.Filter.Prefix{properties: props}
  def build_filter([suffix: props]), do: %Solvent.Filter.Suffix{properties: props}

  def build_filter([any: subs]) do
    %Solvent.Filter.Any{subfilters: Enum.map(subs, &build_filter/1)}
  end

  def build_filter([all: subs]) do
    %Solvent.Filter.All{subfilters: Enum.map(subs, &build_filter/1)}
  end

  def build_filter([not: subfilter]) do
    %Solvent.Filter.Not{subfilter: build_filter(subfilter)}
  end
end
