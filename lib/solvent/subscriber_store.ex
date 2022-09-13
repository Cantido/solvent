defmodule Solvent.SubscriberStore do
  @moduledoc false

  @table_name :solvent_listeners

  def init do
    :ets.new(@table_name, [:bag, :public, :named_table])
  end

  def insert(id, filter, fun) when is_function(fun) do
    true = :ets.insert(@table_name, {id, filter, fun})
    :ok
  end

  def delete(id) do
    true = :ets.match_delete(@table_name, {id, :_, :_})
    :ok
  end

  def delete_all do
    true = :ets.delete_all_objects(@table_name)
    :ok
  end

  require Logger

  def listeners_for(event) do
    listeners = :ets.tab2list(@table_name)

    Logger.info("all listeners: #{inspect listeners, pretty: true}")
    Task.Supervisor.async_stream(Solvent.TaskSupervisor, listeners, fn {id, filter, fun} ->
      if Solvent.Filter.match?(filter, event) do
        {id, filter, fun}
      end
    end)
    |> Stream.reject(fn {:ok, listener} -> is_nil(listener) end)
    |> Stream.map(fn {:ok, listener} -> listener end)
  end
end
