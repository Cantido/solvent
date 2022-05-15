defmodule Solvent.SubscriberStore do
  @table_name :solvent_listeners

  def init do
    :ets.new(@table_name, [:set, :public, :named_table])
  end

  def insert(id, match_type, fun) when is_function(fun) do
    true = :ets.insert(@table_name, {id, match_type, fun})
    :ok
  end

  def to_list do
    :ets.tab2list(@table_name)
  end
end
