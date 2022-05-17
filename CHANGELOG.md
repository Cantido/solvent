# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Handler functions now take an additional argument: the event type.
  Now the signature is `(String.t(), String.t()) -> any()`.
  The `Solvent.Subscriber` behavior was changed to reflect this.
  This was done so that you don't have to fetch the command just to know what
  its type is, which will be useful in handlers that accept multiple types.

[Unreleased]: https://github.com/Cantido/solvent/compare/v0.1.0...HEAD
