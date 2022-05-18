defmodule Solvent.SubscriberStore do
  @moduledoc false

  @table_name :solvent_listeners

  def init do
    :ets.new(@table_name, [:bag, :public, :named_table])
  end

  def insert(id, match_type, fun) when is_function(fun) do
    true = :ets.insert(@table_name, {match_type, id, fun})
    :ok
  end

  def delete(id) do
    true = :ets.match_delete(@table_name, {:_, id, :_})
    :ok
  end

  def delete_all do
    true = :ets.delete_all_objects(@table_name)
    :ok
  end

  def for_event_type(event_type) do
    :ets.match_object(@table_name, {event_type, :_, :_})
  end
end
