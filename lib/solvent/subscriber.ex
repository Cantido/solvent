defmodule Solvent.Subscriber do
  defmacro __using__(usage_opts) do
    quote do
      @behaviour Solvent.Subscriber
      @solvent_listener_id unquote(Keyword.fetch!(usage_opts, :id))
      @solvent_match_type unquote(Keyword.fetch!(usage_opts, :match_type))

      def subscriber_id do
        @solvent_listener_id
      end

      def match_type do
        @solvent_match_type
      end

      defoverridable subscriber_id: 0, match_type: 0
    end
  end

  @callback subscriber_id() :: String.t()
  @callback match_type() :: String.t()
  @callback handle_event(Solvent.Event.t()) :: any()
end
