defmodule Solvent do
  @moduledoc """
  Documentation for `Solvent`.
  """

  def subscribe(match_type, fun) do
    subscribe(UUID.uuid4(), match_type, fun)
  end

  def subscribe(id, match_type, fun) do
    true = :ets.insert(:solvent_listeners, {id, match_type, fun})
    {:ok, id}
  end

  def subscribe(module) when is_atom(module) do
    id = apply(module, :subscriber_id, [])
    match_type = apply(module, :match_type, [])
    fun = fn event_id ->
      apply(module, :handle_event, [event_id])
    end
    subscribe(id, match_type, fun)
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
