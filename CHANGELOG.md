# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

These changes reflect what I've learned while integrating Solvent into other projects,
and while working on projects that also work on CloudEvents.
They have a focus mainly in two places: making more information available to users,
and making the library better follow the CloudEvents spec.

### Added

- The `Solvent.EventStore.fetch!/1` function, which will raise a descriptive error if the event does not exist.
- You can now pass a `Solvent.Event` struct into `Solvent.publish/2` yourself
- `Solvent.Event` can now be encoded to and from JSON, and implements `Jason.Encoder`
- Telemetry events are now documented with `:telemetry_registry`.
- Added `[:solvent, :event, :published]` telemetry event,
  dispatched when an event is.
- Logger metadata is now added before subscriber functions are executed.
  This data includes:
    - `:solvent_event_type` - The dispatched event's type (AKA topic)
    - `:solvent_event_source` - The dispatched event's source
    - `:solvent_event_id` - The dispatched event's ID
    - `:solvent_subscriber_id` - The ID of the subscriber that is currently executing

### Changed

- *Breaking change*: The type matching argument is now required to be a more complex filter argument.
  The argument can either be keyword list filter expression (see the `Solvent.Filter` HexDocs),
  or it can be any struct implementing the `Solvent.Filter` protocol.
- Event IDs are now being returned an accepted as a `{source, id}` tuple.
  This is because the CloudEvents spec only requires that IDs are unique in the scope of the source.

## [0.2.0]

### Changed

- Handler functions now take an additional argument: the event type.
  Now the signature is `(String.t(), String.t()) -> any()`.
  The `Solvent.Subscriber` behavior was changed to reflect this.
  This was done so that you don't have to fetch the command just to know what
  its type is, which will be useful in handlers that accept multiple types.

[Unreleased]: https://github.com/Cantido/solvent/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/Cantido/solvent/compare/v0.1.0...v0.2.0
