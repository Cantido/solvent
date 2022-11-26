defmodule Solvent.Subscriber do
  @moduledoc """
  A module shorthand for defining subscribers.

  Use this module to quickly create a module that can handle Solvent events.

      defmodule MyModule do
        use Solvent.Subscriber, filters: [exact: [type: "myevent.published"]]

        def handle_event(type, event_id) do
          # Fetch and handle your event here
        end
      end

  Then you only need to pass in the module name to `Solvent.subscribe/1`,
  usually done in your `application.ex`, or wherever your code starts.

  By default, module subscribers will automatically call `Solvent.EventStore.ack/2` once `c:handle_event/2` returns.
  To disable this feature, set the `:auto_ack` option to `false`, and then you can acknowledge the event manually.
  This module provides an `auto_ack/1` function that is compiled with the ID of your handler,
  so you only need to provide the event ID.

      defmodule MyModule do
        use Solvent.Subscriber,
          filters: [prefix: [type: "myevents."]],
          auto_ack: false

        def handle_event(type, event_id) do
          # Fetch and handle your event here
          ack_event(event_id)
        end
      end

  Using this module also imports `Solvent.Subscriber.event!/1` which unwraps the result from `Solvent.EventStore.fetch/1`
  and raises if the event is not found.

  ## Options

    - `:filters` - the filter expression to match events against
    - `:id` - the ID to give the subscriber function. Defaults to the current module name.
    - `:auto_ack` - automatically call `Subscriber.EventStore.ack/1` after `c:handle_event/2` returns. Defaults to `true`.
  """

  defmacro __using__(usage_opts) do
    quote do
      import Solvent.Subscriber

      @behaviour Solvent.Subscriber
      @solvent_listener_id unquote(Keyword.get(usage_opts, :id, to_string(__MODULE__)))
      @solvent_source unquote(Keyword.get(usage_opts, :source))
      @solvent_types unquote(Keyword.get(usage_opts, :types))
      @solvent_filters unquote(Keyword.get(usage_opts, :filters, []))
      @solvent_auto_ack unquote(Keyword.get(usage_opts, :auto_ack, true))

      def subscriber_id do
        @solvent_listener_id
      end

      def filter do
        @solvent_filters
      end

      def subscription(opts \\ []) do
        opts = Keyword.merge(opts, [
          id: subscriber_id(),
          source: @solvent_source,
          types: @solvent_types,
          filters: Solvent.build_filters(@solvent_filters)
        ])

        Solvent.Subscription.new(
          {__MODULE__, :run_module, [__MODULE__, subscriber_id(), @solvent_auto_ack]},
          opts
        )
      end

      def auto_ack? do
        @solvent_auto_ack
     end

      def ack_event(event_id) do
        Solvent.EventStore.ack(event_id, subscriber_id())
      end

      defoverridable subscriber_id: 0
    end
  end

  @doc """
  Returns the current subscriber ID.

  This function is automatically created when you `use` this module,
  but you can override it, if you need.
  """
  @callback subscriber_id() :: String.t()

  @doc """
  Returns the filter to match events against.

  This function is automatically created when you `use` this module,
  but you can override it, if you need.
  """
  @callback filter() :: String.t()

  @doc """
  Performs an action when given an event type and event ID.
  """
  @callback handle_event(String.t(), String.t()) :: any()


  def run_module(type, event_id, mod, subscriber_id, auto_ack?) do
    apply(mod, :handle_event, [type, event_id])

    if auto_ack? do
      Solvent.EventStore.ack(event_id, subscriber_id)
    end
  end

  @doc """
  Unwraps the result from `Solvent.EventStore.fetch/1` and raises if the event is not found.
  """
  def event!(event_id) do
    case Solvent.EventStore.fetch(event_id) do
      {:ok, event} -> event
      _ -> raise "Event not found for ID #{inspect event_id}"
    end
  end
end
