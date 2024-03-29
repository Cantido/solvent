# SPDX-FileCopyrightText: 2023 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Solvent.SubscriptionStore do
  @moduledoc """
  Stores `Solvent.Subscription` structs in ETS.
  """

  alias Solvent.Subscription

  @table_name :solvent_subscriptions

  @doc """
  Create the ETS tables that store subscriptions.
  """
  @spec init() :: :ok
  def init do
    :ets.new(@table_name, [:bag, :public, :named_table])
    :ok
  end

  @doc """
  Insert a subscription to the store.
  Once inserted, the subscription's sink will have matching events delivered to it using `Solvent.Sink.deliver/4`.
  """
  @spec insert(Solvent.Subscription.t()) :: :ok
  def insert(%Subscription{} = sub) do
    true = :ets.insert(@table_name, {sub.id, sub})
    :ok
  end

  @doc """
  Remove a subscription from the store.
  Once deleted, the subscription's sink will no longer have matching events delivered to it.
  """
  @spec delete(Solvent.Subscription.id()) :: :ok
  def delete(id) do
    true = :ets.match_delete(@table_name, {id, :_})
    :ok
  end

  @doc """
  Remove all subscriptions from the store.
  """
  @spec delete_all() :: :ok
  def delete_all do
    true = :ets.delete_all_objects(@table_name)
    :ok
  end

  @doc """
  Returns a stream of all subscriptions in the store that match the given event.
  """
  @spec subscriptions_for(Solvent.Event.t()) :: Enumerable.t()
  def subscriptions_for(event) do
    subscriptions = :ets.tab2list(@table_name)

    Task.Supervisor.async_stream(Solvent.TaskSupervisor, subscriptions, fn {_id, sub} ->
      if Subscription.match?(sub, event) do
        sub
      end
    end)
    |> Stream.reject(fn {:ok, sub} -> is_nil(sub) end)
    |> Stream.map(fn {:ok, sub} -> sub end)
  end
end
