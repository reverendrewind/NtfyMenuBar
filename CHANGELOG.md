# Changelog

## [Unreleased]
### Changed
- Replaced debug print statements with Logger utility
- Removed outdated documentation files
- Optimized codebase for open source release

## [v2.5.2] - 2025-09-24
### Added
- MIT LICENSE and open source preparation
- Logger utility for improved debugging

### Fixed
- Do Not Disturb schedule week starting with Saturday instead of Sunday
- Day-to-weekday symbol mapping in settings

### Changed
- Extracted settings components from monolithic SettingsView (19% reduction)
- Component separation following single-responsibility principle

## [v2.5.1] - 2025-09-24
### Fixed
- Message clearing persistence across app restarts
- Notification sounds not playing due to missing file extensions
- High-priority notifications ignoring user sound preferences