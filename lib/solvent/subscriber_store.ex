defmodule Solvent.SubscriberStore do
  @moduledoc false

  alias Solvent.Subscription

  @table_name :solvent_listeners

  def init do
    :ets.new(@table_name, [:bag, :public, :named_table])
  end

  def insert(%Subscription{} = sub) do
    true = :ets.insert(@table_name, {sub.id, sub})
    :ok
  end

  def delete(id) do
    true = :ets.match_delete(@table_name, {id, :_})
    :ok
  end

  def delete_all do
    true = :ets.delete_all_objects(@table_name)
    :ok
  end

  require Logger

  def listeners_for(event) do
    listeners = :ets.tab2list(@table_name)

    Task.Supervisor.async_stream(Solvent.TaskSupervisor, listeners, fn {id, sub} ->
      if Subscription.match?(sub, event) do
        {id, sub}
      end
    end)
    |> Stream.reject(fn {:ok, sub} -> is_nil(sub) end)
    |> Stream.map(fn {:ok, sub} -> sub end)
  end
end
