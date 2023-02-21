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

      @doc """
      Returns a `Solvent.Subscription` struct describing this module's subscription configuration.

      Options can be passed to this function to override values provided to `use Solvent.Subscriber`.
      """
      @spec subscription(keyword()) :: Solvent.Subscription.t()
      def subscription(opts \\ []) do
        sub_opts = Keyword.take(opts, [:id, :sink, :source, :types, :filters, :config])

        merged_config = Keyword.merge(@solvent_config, Keyword.get(sub_opts, :config, []))

        opts =
          [
            id: @solvent_subscription_id,
            source: @solvent_source,
            types: @solvent_types,
            filters: Solvent.build_filters(@solvent_filters)
          ]
          |> Keyword.merge(sub_opts)
          |> Keyword.put(:config, merged_config)

        Solvent.Subscription.new({__MODULE__, :handle_event, []}, opts)
      end

      @doc """
      Acknowledge an event with the given handle.

      This is a shortcut function that has this module's subscription ID set by `use Solvent.Subscriber`.
      """
      @spec ack_event(Solvent.Event.handle()) :: :ok
      def ack_event(event_handle) do
        Solvent.EventStore.ack(event_handle, @solvent_subscription_id)
      end
    end
  end

  @doc """
  Performs an action when given an event type, event handle, and subscription ID.
  """
  @callback handle_event(
    Solvent.Event.type(),
    Solvent.Event.handle(),
    Solvent.Subscription.id()
  ) :: any()
end
