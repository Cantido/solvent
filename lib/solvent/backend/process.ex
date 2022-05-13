defmodule Solvent.Backend.Process do
  use GenServer

  require Logger

  @enforce_keys [:pid]
  defstruct [:pid]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(_) do
    {:ok, MapSet.new()}
  end

  def publish(bus \\ __MODULE__, data) do
    with :ok <- GenServer.cast(bus, {:publish, data}) do
      {:ok, bus}
    end
  end

  def subscribe(bus \\ __MODULE__, fun) do
    with :ok <- GenServer.cast(bus, {:subscribe, fun}) do
      {:ok, bus}
    end
  end

  def handle_cast({:subscribe, fun}, state) do
    {:noreply, MapSet.put(state, fun)}
  end

  def handle_cast({:publish, data}, state) do
    :ok = Enum.each(state, fn fun ->
      fun.(data)
    end)
    {:noreply, state}
  end

  defimpl Solvent.EventBus do
    def publish(%{pid: pid}, data) do
      Solvent.Backend.Process.publish(pid, data)
    end

    def subscribe(%{pid: pid}, fun) do
      Solvent.Backend.Process.subscribe(pid, fun)
    end
  end
end
