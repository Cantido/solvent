defmodule Solvent.Subscriber do
  @moduledoc """
  A module shorthand for defining subscribers.

  Use this module to quickly create a module that can handle Solvent events.

      iex> defmodule MyModule do
      ...>   use Solvent.Subscriber, filters: [exact: [type: "myevent.published"]]
      ...>
      ...>   def handle_event(type, event_id, ) do
      ...>     # Fetch and handle your event here
      ...>   end
      ...> end

  Then you only need to pass in the module name to `Solvent.subscribe/1`,
  usually done in your `application.ex`, or wherever your code starts.

  By default, module subscribers will automatically call `Solvent.EventStore.ack/2` once `c:handle_event/3` returns.
  To disable this feature, set the `:auto_ack` value under the `:config` option to `false`, and then you can acknowledge the event manually.
  This module provides an `ack_event/1` function that is compiled with the ID of your handler,
  so you only need to provide the event ID.

      iex> defmodule MyModule do
      ...>   use Solvent.Subscriber,
      ...>     filters: [prefix: [type: "myevents."]],
      ...>     config: [auto_ack: false]
      ...>
      ...>   def handle_event(type, event_id, _subscription_id) do
      ...>     # Fetch and handle your event here
      ...>     ack_event(event_id)
      ...>   end
      ...> end

  ## Options

  Supports the same options as `Solvent.Subscription.new/2`.
  """

  defmacro __using__(usage_opts) do
    quote do
      @behaviour Solvent.Subscriber
      @solvent_subscription_id unquote(Keyword.get(usage_opts, :id, to_string(__MODULE__)))
      @solvent_source unquote(Keyword.get(usage_opts, :source))
      @solvent_types unquote(Keyword.get(usage_opts, :types))
      @solvent_filters unquote(Keyword.get(usage_opts, :filters, []))
      @solvent_config unquote(Keyword.get(usage_opts, :config, auto_ack: true))

      def subscription(opts \\ []) do
        sub_opts = Keyword.take(opts, [:id, :sink, :source, :types, :filters, :config])

        opts =
          [
            id: @solvent_subscription_id,
            source: @solvent_source,
            types: @solvent_types,
            filters: Solvent.build_filters(@solvent_filters),
            config: @solvent_config
          ]
          |> Keyword.merge(sub_opts)

        Solvent.Subscription.new({__MODULE__, :handle_event, []}, opts)
      end

      def ack_event(event_id) do
        Solvent.EventStore.ack(event_id, @solvent_subscription_id)
      end
    end
  end

  @doc """
  Performs an action when given an event type, event ID, and subscription ID.
  """
  @callback handle_event(String.t(), String.t(), String.t()) :: any()
end
