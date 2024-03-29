# SPDX-FileCopyrightText: 2023 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Solvent do
  use TelemetryRegistry

  telemetry_event(%{
    event: [:solvent, :event, :published],
    description: "Emitted when an event is published",
    measurements: "%{}",
    metadata:
      "%{event_source: String.t(), event_id: String.t(), event_type: String.t(), subscription_count: non_neg_integer()}"
  })

  telemetry_event(%{
    event: [:solvent, :subscription, :processing, :start],
    description: "Emitted when a subscriber begins processing an event",
    measurements: "%{}",
    metadata:
      "%{subscription_id: String.t(), event_source: String.t(), event_id: String.t(), event_type: String.t()}"
  })

  telemetry_event(%{
    event: [:solvent, :subscription, :processing, :stop],
    description: "Emitted when a subscriber finishes processing an event",
    measurements: "%{duration: non_neg_integer()}",
    metadata:
      "%{subscription_id: String.t(), event_source: String.t(), event_id: String.t(), event_type: String.t()}"
  })

  telemetry_event(%{
    event: [:solvent, :subscription, :subscribing, :start],
    description: "Emitted when a subscriber begins subscribing to the event stream",
    measurements: "%{}",
    metadata: "%{subscription_id: String.t(), filter: String.t()}"
  })

  telemetry_event(%{
    event: [:solvent, :subscription, :subscribing, :stop],
    description: "Emitted when a subscriber is finished subscribing to the event stream",
    measurements: "%{duration: non_neg_integer()}",
    metadata: "%{subscription_id: String.t(), filter: String.t()}"
  })

  @moduledoc """
  Solvent is an event bus built to be fast and easy-to-use,
  and takes a lot of inspiration from the [CloudEvents](https://cloudevents.io) spec for the best interoperability with other event systems.

  In the CloudEvents specification, every event is required to have an ID, a source, and a type.
  The `source` field identifies the system that sent the event, and the ID must identify the event and be unique in the scope of the source.
  Lastly, the `type` field, also called a "topic," identifies the kind of event that took place.

  In Solvent, only the `type` field is required, but it is strongly recommended to provide a `source` field as well.
  Solvent generates a version 7 UUID for event ID fields and this rarely needs to be overridden.
  See the `Solvent.Event` docs for details on what defaults are provided.

  Subscribe to the event stream with `subscribe/2`, and publish events using `publish/2`.
  You can also create a `Solvent.Subscription` or a `Solvent.Event` yourself and pass those to `subscribe/1` and `publish/1`, respectively.
  The functions here share a signature with their corresponding struct functions, but have the additional benefit of interacting with the event bus.

  ## Telemetry

  #{telemetry_docs()}

  """

  alias Solvent.Event
  alias Solvent.Sink
  alias Solvent.Subscription

  require Logger

  @type sink :: module() | Sink.t()
  @type event_or_type :: Event.t() | Event.type()

  @doc """
  Subscribe to the event stream with a pre-made `Solvent.Subscription` struct.
  """
  @spec subscribe(Subscription.t()) :: {:ok, Subscription.id()}
  def subscribe(%Subscription{} = sub) do
    :telemetry.span(
      [:solvent, :subscription, :subscribing],
      %{subscription_id: sub.id, filter: sub.filters},
      fn ->
        :ok = Solvent.SubscriptionStore.insert(sub)
        {:ok, %{}}
      end
    )

    {:ok, sub.id}
  end

  @doc """
  Subscribe to the event stream.

  The sink is what receives your events, and can be anything that implements the `Solvent.Sink` protocol,
  which includes anonymous functions, module-function-args tuples, and PIDs.
  Here's an example with a module-function-args tuple that subscribes to a single event type
  and identifies the subscription as `"My first subscriber"`.

      iex> Solvent.subscribe(
      ...>  {Solvent.MessengerHandler, :handle_event, []},
      ...>  types: ["com.example.event.published"],
      ...>  id: "My first subscriber"
      ...> )
      {:ok, "My first subscriber"}

  This function shares its signature with `Solvent.Subscription.new/2`,
  and creates a `Solvent.Subscription` in the same way,
  while also inserting the subscription into the `Solvent.SubscriptionStore` so that the sink will begin to receive events.

  Sinks are given an event _identifier_, and _not_ the event itself.
  Your sink must fetch the full event from the `Solvent.EventStore`, so that extra data is not copied between processes.
  You must also call `Solvent.EventStore.ack/2` once you are done with the event,
  unless you want the event to stay in the event store forever.

  > #### Tip {: .tip}
  >
  > Use the `Solvent.Subscriber` module to make a self-contained subscriber module.

  You can also create a `Solvent.Subscription` struct yourself, and pass it to `subscribe/1`.
  """
  @spec subscribe(sink(), Keyword.t()) :: {:ok, Subscription.id()}
  def subscribe(sink, opts \\ [])

  def subscribe(module, opts) when is_atom(module) and is_list(opts) do
    subscription = apply(module, :subscription, [opts])

    subscribe(subscription)
  end

  def subscribe(sink, opts) do
    sub = Subscription.new(sink, opts)

    subscribe(sub)
  end

  @doc """
  Remove a subscriber.
  """
  @spec unsubscribe(Subscription.id()) :: :ok
  def unsubscribe(id) do
    Solvent.SubscriptionStore.delete(id)
  end

  @doc """
  Publish an event to the event bus, triggering all subscriber functions.

  Only a type (AKA "topic") is required. All other fields can be supplied using the options.
  See `Solvent.Event` for details on what that struct contains.
  All values given as options are inserted into the event struct.

  ID values are version 7 UUIDs by default, and you don't need to provide them.

  I would recommend using the CloudEvents format for your event's `type` field, which starts with a reversed DNS name, and is dot-separated.
  This will help avoid collisions with events from other applications.

      Solvent.publish("io.github.cantido.myevent.published")
      {:ok, "0b06bdb7-06a7-4df9-a825-1fd225ceea43"}

  It is also recommended to provide a `source` option to identify your application, especially if your subscription did not specify a `source`.
  Otherwise, all events will be published with a default source, and subscriptions will be triggered for every event traveling through Solvent (including events from other applications).
  A good `source` value is either a fully-qualified domain name, or a UUID in URN format.

      iex> Solvent.publish(
      ...>   "io.github.cantido.documentation.read",
      ...>   id: "read-docs-id",
      ...>   source: "myapp"
      ...> )
      {:ok, {"myapp", "read-docs-id"}}

  You can also build an event yourself with `Solvent.Event.new/1` and publish it with this function.
  """
  @spec publish(event_or_type(), Keyword.t()) :: {:ok, Event.handle()}
  def publish(event, opts \\ [])

  def publish(type, opts) when is_binary(type) do
    event = Solvent.Event.new(type, opts)
    publish(event, opts)
  end

  def publish(event, _opts) do
    Task.Supervisor.start_child(Solvent.TaskSupervisor, fn -> do_publish(event) end)

    {:ok, {event.source, event.id}}
  end

  defp do_publish(event) do
    subscriptions = Solvent.SubscriptionStore.subscriptions_for(event)
    subscription_ids = Enum.map(subscriptions, & &1.id) |> Enum.uniq()

    Logger.debug(
      event: event,
      subscriptions: subscriptions
    )

    :telemetry.execute(
      [:solvent, :event, :published],
      %{},
      %{
        event_source: event.source,
        event_id: event.id,
        event_type: event.type,
        subscription_count: Enum.count(subscriptions)
      }
    )

    if Enum.count(subscriptions) > 0 do
      :ok = Solvent.EventStore.insert(event, subscription_ids)
    else
      Logger.warn(
        "No subscriptions matched event type #{event.type}. Solvent will not insert the event into the event store."
      )
    end

    Task.Supervisor.async_stream(
      Solvent.TaskSupervisor,
      subscriptions,
      &notify(&1, event),
      timeout: :infinity
    )
    |> Stream.run()
  end

  defp notify(subscription, event) do
    :telemetry.span(
      [:solvent, :subscription, :processing],
      %{
        subscription: subscription.id,
        event_source: event.source,
        event_id: event.id,
        event_type: event.type
      },
      fn ->
        # credo:disable-for-next-line Credo.Check.Warning.MissedMetadataKeyInLoggerConfig
        Logger.metadata(
          solvent_subscription_id: subscription.id,
          solvent_event_source: event.source,
          solvent_event_id: event.id,
          solvent_event_type: event.type
        )

        Solvent.Sink.deliver(subscription.sink, event, subscription.id)

        if Keyword.get(subscription.config, :auto_ack, false) do
          Solvent.EventStore.ack({event.source, event.id}, subscription.id)
        end

        {:ok, %{}}
      end
    )
  end

  @doc """
  Build a `Solvent.Filter` struct from a nested keyword list of filters.
  """
  @spec build_filters(Keyword.t()) :: Solvent.Filter.t()
  def build_filters(filters) when is_list(filters) do
    Enum.map(filters, &build_filter/1)
  end

  defp build_filter({:exact, props}), do: %Solvent.Filter.Exact{properties: props}
  defp build_filter({:prefix, props}), do: %Solvent.Filter.Prefix{properties: props}
  defp build_filter({:suffix, props}), do: %Solvent.Filter.Suffix{properties: props}

  defp build_filter({:any, subs}) do
    %Solvent.Filter.Any{subfilters: build_filters(subs)}
  end

  defp build_filter({:all, subs}) do
    %Solvent.Filter.All{subfilters: build_filters(subs)}
  end

  defp build_filter({:not, subfilter}) do
    %Solvent.Filter.Not{subfilter: build_filter(subfilter)}
  end
end
