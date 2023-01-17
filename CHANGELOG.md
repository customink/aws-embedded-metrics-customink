
# Keep A Changelog!

See this http://keepachangelog.com link for information on how we want this documented formatted.

## v0.7.0

### Added

- A new `Tcp` sink is added. The `Tcp` sink can send EMF messages to any valid TCP endpoint.
- `tcp-client` will be required at runtime if you use the `Tcp` sink. Originally a small hand-written TCP client was used but it proved unreliable and well outside the scope of this library.
- Added the new `Units` class for easy reference to the accepted metric units.

## v0.6.0

### Fixed

- Moved concurrent-ruby to runtime dep.

## v0.5.0

### Added

- Simple singleton/delegator for metrics instance in Rails.

## v0.4.0

### Changed

- Use Concurrent Ruby for Logger data.

## v0.3.0

### Added

- New `benchmark` helper.

## v0.2.0

### Changed

- `Lambda` sink renamed to `Stdout` to reflect its destination rather than its intended use
- The currently configured sink is now accessed through the `Config` object rather than from the root namespace
- Improved test coverage

### Added

- A `Logger` sink to emit to a Ruby Logger instance, for logfile output

## v0.1.0

### Added

- Initial Release!!! 🎉🎊🥳
