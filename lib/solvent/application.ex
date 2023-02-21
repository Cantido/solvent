defmodule Solvent.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Solvent.EventStore.init()
    Solvent.SubscriptionStore.init()

    children = [
      # Starts a worker by calling: Solvent.Worker.start_link(arg)
      # {Solvent.Worker, arg}
      {Task.Supervisor, name: Solvent.TaskSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Solvent.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
