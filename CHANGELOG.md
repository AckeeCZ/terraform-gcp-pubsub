# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v2.0.0] - 2022-03-24
### Changed
- support for `retry_policy`, now accepts as block instead of `minimum_backoff` and `maximum_backoff`

## [v1.2.0] - 2022-03-23
### Added
- support for `push_config`

## [v1.1.2] - 2022-03-22
### Fixed
- ack deadline handling

## [v1.1.1] - 2021-12-01
### Fixed
- wrong string compare in dlq setup

## [v1.1.0] - 2021-11-25
### Added
- `message_retention_duration` variable

## [v1.0.0] - 2021-09-21
- initial release
