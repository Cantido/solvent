defmodule Solvent do
  @moduledoc """
  Solvent is an event bus built to be fast and easy-to-use.

  Publish and subscribe to events here.
  You can either provide a function to be run, with `subscribe/2` and `subscribe/3`,
  or subscribe a module using `subscribe/1`.
  See the docs for `Solvent.Subscriber` for more information on module subscribers.

      iex> Solvent.subscribe("My first subscriber", ~r/.*/, fn event_id ->
      ...>   {:ok, event} = Solvent.EventStore.fetch(event_id)
      ...>
      ...>   # play with the event, and delete it when you're done
      ...>
      ...>   Solvent.EventStore.delete(event_id)
      ...> end)
      {:ok, "My first subscriber"}

  It's important to observe that subscriber functions are given the _identifier_ of an event, _not_ the event itself.

  Once you have a subscriber, publish an event.
  Data is optional, only a type is required.
  This can be any string.
  I would recommend the CloudEvents format, which starts with a reversed DNS name, and is dot-separated.
  This will help avoid collisions with events you have no desire to collide with.

      iex> Solvent.publish("io.github.cantido.myevent.published")
      :ok

  Here you can also supply data for the event with the `:data` option.

      iex> Solvent.publish("io.github.cantido.myevent.published", data: "Hello, world!")
      :ok

  This will be available on the `:data` key of the event object you fetch from `Solvent.EventStore`.
  See the `Solvent.Event` docs for more information on what that struct contains.
  """

  @doc """
  Like `subscribe/3` with an auto-generated ID.

  By default, the ID will be a version 4 UUID.
  """
  def subscribe(match_type, fun) do
    subscribe(UUID.uuid4(), match_type, fun)
  end

  @doc """
  Execute a function when an event is published.

  The `match_type` argument can be either a string or a regular expression.
  It is matched with an event's type using the `Kernel.=~/2` operator.

  The function argument will be given the ID of the event.
  You must fetch the event from `Solvent.EventStore` if you wish to use it.

  The ID is optional, and defaults to a version 4 UUID.

      iex> Solvent.subscribe("My subscriber", "event.published", fn event_id ->
      ...>   {:ok, event} = Solvent.EventStore.fetch(event_id)
      ...>   # Use the event, then delete it
      ...>   Solvent.EventStore.delete(event_id)
      ...> end)
      {:ok, "My subscriber"}
  """
  def subscribe(id, match_type, fun) do
    true = :ets.insert(:solvent_listeners, {id, match_type, fun})
    {:ok, id}
  end

  @doc """
  Subscribe a module to the event bus.

  See `Solvent.Subscriber` for details.
  """
  def subscribe(module) when is_atom(module) do
    id = apply(module, :subscriber_id, [])
    match_type = apply(module, :match_type, [])
    fun = fn event_id ->
      apply(module, :handle_event, [event_id])
    end
    subscribe(id, match_type, fun)
  end

  @doc """
  Publish an event to the event bus, triggering all subscriber functions.

  Only a type (AKA "topic") is required.
  All other fields can be supplied using the options.
  See `Solvent.Event` for details on what that struct contains.
  All values given as options are inserted into the event struct.

  ## Examples

      iex> Solvent.publish("io.github.cantido.documentation.read")
      :ok

      iex> Solvent.publish(
      ...>   "io.github.cantido.documentation.read",
      ...>   datacontenttype: "application/json",
      ...>   data: ~s({"hello":"world"})
      ...> )
      :ok
  """
  def publish(type, opts \\ []) do
    event = %Solvent.Event{
      id: Keyword.get(opts, :id, UUID.uuid4()),
      source: "Solvent",
      type: type,
      time: DateTime.utc_now()
    }
    |> struct!(opts)

    :ok = Solvent.EventStore.insert(event)
    notifier_fun = fn {_listener_id, match_type, fun}, _acc ->
      Task.Supervisor.start_child(Solvent.TaskSupervisor, fn ->
        if event.type =~ match_type do
          fun.(event.id)
        end
        :ok
      end)
    end

    Task.Supervisor.start_child(Solvent.TaskSupervisor, fn ->
      _acc = :ets.foldl(notifier_fun, nil, :solvent_listeners)
    end)

    :ok
  end
end
