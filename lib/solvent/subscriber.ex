defmodule Solvent.Subscriber do
  @moduledoc """
  A module shorthand for defining subscribers.

  Use this module to quickly create a module that can handle Solvent events.

      defmodule MyModule do
        use Solvent.Subscriber, match_type: ~r/myevents.*/

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
          match_type: ~r/myevents.*/,
          auto_ack: false

        def handle_event(type, event_id) do
          # Fetch and handle your event here
          ack_event(event_id)
        end
      end

  ## Options

    - `:id` - the ID to give the subscriber function. Defaults to the current module name.
    - `:match_type` - a string or regex to match event types. Defaults to `~r/.*/`, which will match every event.
    - `:auto_ack` - automatically call `Subscriber.EventStore.ack/1` after `c:handle_event/2` returns. Defaults to `true`.
  """

  defmacro __using__(usage_opts) do
    quote do
      @behaviour Solvent.Subscriber
      @solvent_listener_id unquote(Keyword.get(usage_opts, :id, to_string(__MODULE__)))
      @solvent_match_type unquote(Keyword.get(usage_opts, :match_type, ~r/.*/))
      @solvent_auto_ack unquote(Keyword.get(usage_opts, :auto_ack, true))

      def subscriber_id do
        @solvent_listener_id
      end

      def match_type do
        @solvent_match_type
      end

      def auto_ack? do
        @solvent_auto_ack
      end

      def ack_event(event_id) do
        Solvent.EventStore.ack(event_id, subscriber_id())
      end

      defoverridable subscriber_id: 0
      defoverridable match_type: 0
    end
  end

  @doc """
  Returns the current subscriber ID.

  This function is automatically created when you `use` this module,
  but you can override it, if you need.
  """
  @callback subscriber_id() :: String.t()

  @doc """
  Returns the value to match event types against.

  This function is automatically created when you `use` this module,
  but you can override it, if you need.
  """
  @callback match_type() :: String.t()

  @doc """
  Performs an action when given an event type and event ID.
  """
  @callback handle_event(String.t(), String.t()) :: any()
end
