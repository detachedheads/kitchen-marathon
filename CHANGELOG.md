# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
- Nothing at this time.

## [0.0.2]
### Changes
- Remove unnecessary ssh configuration params -- this is handled by the transport.
- Renamed the proxy configuration pieces to be reflecting of being tied to marathon host.
- Fixed an issue with the merging of the 3 configuration pieces with regards to symbols and deep merging sanity.
- Changed the default prefix to include the forward slash -- making it optional.
- Fixed an issue with how app_id was managed in state that allows for apps to not be cleaned up properly.

# 0.0.1
### Added
- Initial internal release

[Unreleased]: https://github.com/yieldbot/kitchen-marathon/compare/kitchen-marathon-0.0.2...HEAD
[0.0.2]: https://github.com/yieldbot/kitchen-master/compare/kitchen-marathon-0.0.1...kitchen-marathon-0.0.2