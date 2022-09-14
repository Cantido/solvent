defmodule Solvent.Bench do
  use Benchfella

  @num_listeners 100

  setup_all do
    :ok = Logger.put_application_level(:solvent, :error)
    Application.ensure_all_started(:solvent)
  end

  bench "insert event with few listeners", [listeners: gen_listeners()] do
    Solvent.publish("com.example.listened.event", source: "benchmark")
    :ok
  end

  defp gen_listeners do
    Enum.each(1..@num_listeners, fn _ ->
      Solvent.subscribe(gen_filter(), fn _, _ -> Process.sleep(500) end)
    end)
  end

  defp gen_filter do
    dialect = Enum.random([:exact, :prefix, :suffix, :all, :any, :not])

    case dialect do
      :exact -> [exact: [type: "com.example.listened.event"]]
      :prefix -> [prefix: [type: "com.example.listened."]]
      :suffix -> [suffix: [type: ".listened.event"]]
      :all -> [all: [[prefix: [type: "com.example.listened."]], [exact: [source: "benchmark"]]]]
      :any -> [any: [[prefix: [type: "com.example.listened."]], [exact: [type: "com.example.other_event"]]]]
      :not -> [not: [exact: [type: "com.example.nolistener"]]]
    end
  end
end
