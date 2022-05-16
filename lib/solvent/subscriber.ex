defmodule Solvent.Subscriber do
  @moduledoc """
  A module shorthand for defining subscribers.

  Use this module to quickly create a module that can handle Solvent events.

      defmodule MyModule do
        use Solvent.Subscriber, match_type: ~r/myevents.*/

        def handle_event(event_id) do
          # Fetch and handle your event here
        end
      end

  Then you only need to pass in the module name to `Solvent.subscribe/1`,
  usually done in your `application.ex`, or wherever your code starts.

  ## Options

    - `:id` - the ID to give the subscriber function. Defaults to the current module name.
    - `:match_type` - a string or regex to match event types. Defaults to `~r/.*/`, which will match every event.
  """

  defmacro __using__(usage_opts) do
    quote do
      @behaviour Solvent.Subscriber
      @solvent_listener_id unquote(Keyword.get(usage_opts, :id, to_string(__MODULE__)))
      @solvent_match_type unquote(Keyword.get(usage_opts, :match_type, ~r/.*/))

      def subscriber_id do
        @solvent_listener_id
      end

      def match_type do
        @solvent_match_type
      end

      def ack_event(event_id) do
        Solvent.EventStore.ack(event_id, subscriber_id())
      end

      defoverridable subscriber_id: 0
      defoverridable match_type: 0
    end
  end

  @callback subscriber_id() :: String.t()
  @callback match_type() :: String.t()
  @callback handle_event(String.t()) :: any()
end
