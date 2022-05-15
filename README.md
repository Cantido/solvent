# Solvent

An event bus built for ease-of-use.



## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `solvent` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:solvent, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/solvent>.

## Usage

Create an event handler by using the `Solvent.Subscriber` module,
and implement its `handle_event/1` callback.

```elixir
defmodule MySubscriber do
  use Solvent.Subscriber

  @impl true
  def handle_event(_event_id) do
    IO.puts("I'm handling an event!")
  end
end
```

Then, in your application's `start/2` function, tell Solvent to subscribe it.

```elixir
def start(_type, _args) do
  Solvent.subscribe(MySubscriber)

  children = [
    # ...
  ]
  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

Finally, publish your event using `Solvent.publish/2`.

```elixir
Solvent.publish("com.myevent.published")
```

Specify additonal event data with the `:data` option.
You can specify any optional field from the CloudEvent spec, in fact.

```elixir
Solvent.publish(
  "com.myjsonevent.published",
  datacontenttype: "application/json",
  data: ~s({"foo":"bar"})
)
```

Only event IDs are passed to subscriber functions.
You must fetch the associated event using `Solvent.EventStore.fetch/1`.
This small hiccup in an otherwise buttery-smooth developer experience is done in the name of speed.
Copying large amounts of data between processes can be slow,
so Solvent stores events in an ETS table and lets you fetch them when you're ready.

## License

MIT License

Copyright 2022 Rosa Richter

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
