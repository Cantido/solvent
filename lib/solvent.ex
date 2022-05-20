defmodule Solvent do
  @moduledoc """
  Solvent is an event bus built to be fast and easy-to-use.

  Publish and subscribe to events here.
  You can either provide a function to be run, with `subscribe/2` and `subscribe/3`,
  or subscribe a module using `subscribe/1`.
  See the docs for `Solvent.Subscriber` for more information on module subscribers.

      iex> Solvent.subscribe("My first subscriber", ~r/.*/, fn _type, event_id ->
      ...>   {:ok, _event} = Solvent.EventStore.fetch(event_id)
      ...>
      ...>   # play with the event, and acknowledge it when you're done
      ...>
      ...>   Solvent.EventStore.ack(event_id, "My first subscriber")
      ...> end)
      {:ok, "My first subscriber"}

  It's important to observe that subscriber functions are given the _identifier_ of an event, _not_ the event itself.
  Also, note that we call `Solvent.EventStore.ack/2` once we're done with the event,
  so that Solvent knows it can clean up the event from the store.

  > #### Tip {: .tip}
  >
  > Use the `Solvent.Subscriber` module to make a subscriber that automatically acknowledges events,
  > along with lots of other nice features.

  Once you have a subscriber, publish an event.
  Data is optional, only a type is required.
  This can be any string.
  I would recommend the CloudEvents format, which starts with a reversed DNS name, and is dot-separated.
  This will help avoid collisions with events from other applications.

      iex> Solvent.publish("io.github.cantido.myevent.published", id: "0b06bdb7-06a7-4df9-a825-1fd225ceea43")
      {:ok, "0b06bdb7-06a7-4df9-a825-1fd225ceea43"}

  Here you can also supply data for the event with the `:data` option.

      iex> Solvent.publish("io.github.cantido.myevent.published", data: "Hello, world!", id: "d0f63676-b853-4f30-8bcf-ea10f2184556")
      {:ok, "d0f63676-b853-4f30-8bcf-ea10f2184556"}

  This will be available on the `:data` key of the event object you fetch from `Solvent.EventStore`.
  See the `Solvent.Event` docs for more information on what that struct contains.
  """

  @doc """
  Subscribe to the event bus.

  When the first argument is a module, the module is subscribed to the event bus,
  and the second argument is expected to be a list of options, if it is provided at all.
  See `Solvent.Subscriber` for details.

  If the first argument is a string or regex, then the second argument must be a function,
  and the function behaves exactly like `subscribe/3` but with an auto-generated ID.
  """
  def subscribe(arg1, arg2 \\ [])

  def subscribe(module, opts) when is_atom(module) and is_list(opts) do
    id = Keyword.get(opts, :id, apply(module, :subscriber_id, []))
    match_type = Keyword.get(opts, :match_type, apply(module, :match_type, []))
    auto_ack? = Keyword.get(opts, :auto_ack, apply(module, :auto_ack?, []))

    fun = fn type, event_id ->
      apply(module, :handle_event, [type, event_id])

      if auto_ack? do
        Solvent.EventStore.ack(event_id, id)
      end
    end

    subscribe(id, match_type, fun)
  end

  def subscribe(match_type, fun) when is_function(fun) do
    subscribe(UUID.uuid4(), match_type, fun)
  end

  @doc """
  Execute a function when an event is published.

  The `match_type` argument can be either a string or a regular expression.
  It is matched with an event's type using the `Kernel.=~/2` operator.

  The function argument will be given the ID of the event.
  You must fetch the event from `Solvent.EventStore` if you wish to use it.

  The ID is optional, and defaults to a version 4 UUID.

      iex> Solvent.subscribe("My subscriber", "subscriber.event.published", fn event_id ->
      ...>   {:ok, _event} = Solvent.EventStore.fetch(event_id)
      ...>   # Use the event, then delete it
      ...>   Solvent.EventStore.delete(event_id)
      ...> end)
      {:ok, "My subscriber"}

  The second argument, `match_types`, can be either a string or a list of strings.
  """
  def subscribe(id, match_type, fun) when is_function(fun) do
    :telemetry.span(
      [:solvent, :subscriber, :subscribing],
      %{subscriber_id: id, match_type: match_type},
      fn ->
        List.wrap(match_type)
        |> Enum.uniq()
        |> Enum.each(fn match_type ->
          :ok = Solvent.SubscriberStore.insert(id, match_type, fun)
        end)
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

  ID values are version 4 UUIDs by default, and you don't need to provide them.
  ## Examples

      Solvent.publish("io.github.cantido.documentation.read")
      {:ok, "some-random-uuid"}

      iex> Solvent.publish(
      ...>   "io.github.cantido.documentation.read",
      ...>   id: "read-docs-id",
      ...>   datacontenttype: "application/json",
      ...>   data: ~s({"hello":"world"})
      ...> )
      {:ok, "read-docs-id"}
  """
  def publish(type, opts \\ []) do
    event = Solvent.Event.new(type, opts)
    subscribers = Solvent.SubscriberStore.for_event_type(type)
    subscriber_ids = Enum.map(subscribers, &elem(&1, 1)) |> Enum.uniq()
    :ok = Solvent.EventStore.insert(event, subscriber_ids)

    notifier_fun = fn {subscriber_id, _match_type, fun} ->
      Task.Supervisor.start_child(Solvent.TaskSupervisor, fn ->
        :telemetry.span(
          [:solvent, :subscriber, :processing],
          %{subscriber_id: subscriber_id, event_id: event.id, event_type: event.type},
          fn ->
            Logger.metadata(subscriber_id: subscriber_id, event_id: event.id, event_type: event.type)
            fun.(event.type, event.id)
            {:ok, %{}}
          end
        )

        :ok
      end)
    end

    Task.Supervisor.start_child(Solvent.TaskSupervisor, fn ->
      Task.Supervisor.async_stream(Solvent.TaskSupervisor, subscribers, notifier_fun,
        timeout: :infinity
      )
      |> Stream.run()
    end)

    {:ok, event.id}
  end
end
