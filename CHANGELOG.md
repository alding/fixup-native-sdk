# Changelog

## 1.2.0

- Synchronized the native decoration component implementation from the host project.
- Published the SDK as a binary-only Swift Package backed by an XCFramework.
- Kept host capabilities, App Store review notes, privacy metadata, and integration APIs unchanged.

## 1.1.1

- Fixed agent-visible combination cards to filter configured Type 49 items by the returned visibility IDs.
- Fixed horizontal content aggregation sizing and channel price alignment.
- Fixed live-info suffix color and product title truncation behavior.

## 1.1.0

- Added `FixupHomeOptions`, `FixupModuleHost.setHost`, and `FixupModuleHost.refresh`.
- Added URL-based endpoint configuration.
- Prevented stale refresh responses from updating a newer account or live-room session.
- Added a cancellable refresh result for superseded requests and session resets.
- Added Chinese integration, App Store review, privacy, and component-boundary documentation.
- Added GitHub Actions build and test validation plus security and third-party dependency notes.

## 1.0.0

- Added `FixupModuleHomeCoordinator` for public native home page creation, refresh, hydration, and reset.
- Added `FixupModuleHost.makeHomeViewController` and `FixupModuleHost.refreshHome`.
- Added explicit SDK errors for missing configuration and missing host capabilities.
- Added a complete Chinese integration guide in `README.zh-CN.md`.
- Updated the host application integration to use the public SDK coordinator.

## Unreleased

- Added typed endpoint configuration through `FixupModuleConfiguration`.
- Added configuration validation through `isConfigured` and `configurationErrors`.
- Added explicit host bridge setup and teardown through `FixupModuleHost`.
- Added initial configuration tests.

## 0.1.0

- Published the initial native decoration component Swift Package.
