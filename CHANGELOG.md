# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2022-11-26

These changes reflect what I've learned while integrating Solvent into other projects,
and while working on projects that also work on CloudEvents.
They have a focus mainly in two places: making more information available to users,
and making the library better follow the CloudEvents spec.

### Added

- The `Solvent.EventStore.fetch!/1` function, which will raise a descriptive error if the event does not exist.
- You can now pass a `Solvent.Event` struct into `Solvent.publish/2` yourself
- Telemetry events are now documented with `:telemetry_registry`.
- Added `[:solvent, :event, :published]` telemetry event,
  dispatched when an event is published.
- Logger metadata is now added before subscriber functions are executed.
  This data includes:
    - `:solvent_event_type` - The dispatched event's type (AKA topic)
    - `:solvent_event_source` - The dispatched event's source
    - `:solvent_event_id` - The dispatched event's ID
    - `:solvent_subscriber_id` - The ID of the subscriber that is currently executing

### Changed

- *Breaking change*: `Solvent.subscribe` now accepts anything that implements the `Solvent.Sink` protocol.
  This is implemented for anonymous functions, tuples (which are interpreted as a module-function-args tuple), and PIDs, which will be sent a message.
  The function signature of `subscribe` also changed such that the sink is the first argument to subscribe.
- *Breaking change*: Structs from the [`cloudevents`](https://github.com/kevinbader/cloudevents-ex)
  are now the event struct of choice, replacing `Solvent.Event`.
  You can still create these structs with `Solvent.Event.new/2`, but they will now be a version 1.0 `cloudevents` struct.
- Event IDs are now being returned and accepted as a `{source, id}` tuple.
  This is because the CloudEvents spec only requires that IDs are unique in the scope of the source.

### How to upgrade

- Replace all string type arguments to `Solvent.subscribe` with a `type: "com.example.mytype"` optional argument.

```elixir
# Before
Solvent.subscribe("com.example.event.published", fn -> IO.puts("Hello!") end)

# After
Solvent.subscribe([exact: [type: "com.example.event.published"]], {IO, :puts, ["Hello!"]})
```

## [0.2.0]

### Changed

- Handler functions now take an additional argument: the event type.
  Now the signature is `(String.t(), String.t()) -> any()`.
  The `Solvent.Subscriber` behavior was changed to reflect this.
  This was done so that you don't have to fetch the command just to know what
  its type is, which will be useful in handlers that accept multiple types.

[Unreleased]: https://github.com/Cantido/solvent/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/Cantido/solvent/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/Cantido/solvent/compare/v0.1.0...v0.2.0
