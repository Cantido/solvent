defmodule Solvent.Backend.Process do
  use GenServer

  require Logger

  @enforce_keys [:pid]
  defstruct [:pid]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def new do
    with {:ok, pid} <- start_link() do
      {:ok, %__MODULE__{pid: pid}}
    end
  end

  def init(_) do
    with {:ok, set} <- Solvent.Backend.Set.new() do
      {:ok, set}
    end
  end

  def handle_cast({:subscribe, id, match_type, fun}, bus) do
    {:ok, bus} = Solvent.EventBus.subscribe(bus, id, match_type, fun)
    {:noreply, bus}
  end

  def handle_cast({:publish, event}, bus) do
    {:ok, bus} = Solvent.EventBus.publish(bus, event)
    {:noreply, bus}
  end

  def handle_cast({:unsubscribe, id}, bus) do
    {:ok, bus} = Solvent.EventBus.unsubscribe(bus, id)
    {:noreply, bus}
  end

  def handle_call({:get_listener, id}, _from, bus) do
    {:ok, result} = Solvent.EventBus.get_listener(bus, id)
    {:reply, result, bus}
  end

  defimpl Solvent.EventBus do
    def publish(bus, event) do
      with :ok <- GenServer.cast(bus.pid, {:publish, event}) do
        {:ok, bus}
      end
    end

    def subscribe(bus, id, match_type, fun) do
      with :ok <- GenServer.cast(bus.pid, {:subscribe, id, match_type, fun}) do
        {:ok, bus}
      end
    end

    def unsubscribe(bus, id) do
      with :ok <- GenServer.cast(bus.pid, {:unsubscribe, id}) do
        {:ok, bus}
      end
    end

    def get_listener(bus, id) do
      GenServer.call(bus.pid, {:get_listener, id})
    end
  end
end
