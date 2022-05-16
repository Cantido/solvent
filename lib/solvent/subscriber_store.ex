defmodule Solvent.SubscriberStore do
  @moduledoc false

  @table_name :solvent_listeners

  def init do
    :ets.new(@table_name, [:set, :public, :named_table])
  end

  def insert(id, match_type, fun) when is_function(fun) do
    true = :ets.insert(@table_name, {id, match_type, fun})
    :ok
  end

  def delete(id) do
    true = :ets.delete(@table_name, id)
    :ok
  end

  def to_list do
    :ets.tab2list(@table_name)
  end
end
