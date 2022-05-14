defmodule Solvent do
  @moduledoc """
  Documentation for `Solvent`.
  """

  def subscribe(id, match_type, fun) do
    true = :ets.insert(:solvent_listeners, {id, match_type, fun})
    :ok
  end

  def publish(type, opts \\ []) do
    event = %Solvent.Event{
      id: Keyword.get(opts, :id, UUID.uuid4()),
      source: "Solvent",
      type: type,
    }
    |> struct!(opts)

    :ok = Solvent.EventStore.insert(event)
    notifier_fun = fn {_listener_id, match_type, fun}, _acc ->
      if event.type =~ match_type do
        fun.(event.id)
      end
      nil
    end

    _acc = :ets.foldl(notifier_fun, nil, :solvent_listeners)
    :ok
  end
end
