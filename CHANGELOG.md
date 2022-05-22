# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Lists of event types can now be subscribed.
- Logger metadata is now added before subscriber functions are executed.
  This data includes:
    - `:solvent_event_type` - The dispatched event's type (AKA topic)
    - `:solvent_event_id` - The dispatched event's ID
    - `:solvent_subscriber_id` - The ID of the subscriber that is currently executing

### Changed

- Regexes can no longer be subscribed. You cannot match them with matchspecs
  in ETS arguments, so searching for subscribers will be dramatically slower
  if I have to scan through the table matching regexes. Besides, you should
  know exactly what events you're matching.

## [0.2.0]

### Changed

- Handler functions now take an additional argument: the event type.
  Now the signature is `(String.t(), String.t()) -> any()`.
  The `Solvent.Subscriber` behavior was changed to reflect this.
  This was done so that you don't have to fetch the command just to know what
  its type is, which will be useful in handlers that accept multiple types.

[Unreleased]: https://github.com/Cantido/solvent/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/Cantido/solvent/compare/v0.1.0...v0.2.0
