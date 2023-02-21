# SPDX-FileCopyrightText: 2023 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Solvent.EventStore.Base do
  @moduledoc """
  The definition of an event store module.

  Modules using this behavior can be used with the `Solvent.EventStore` module to publish and fetch events.
  """

  alias Solvent.Event
  alias Solvent.Subscription

  @callback init() :: :ok
  @callback fetch(Event.handle()) :: {:ok, Event.t()} | :error
  @callback fetch!(Event.handle()) :: Event.t()
  @callback insert(Event.t(), list(Subscription.id())) :: :ok
  @callback delete(Event.handle()) :: :ok
  @callback delete_all() :: :ok
  @callback ack(Event.handle(), Subscription.id()) :: :ok
end
