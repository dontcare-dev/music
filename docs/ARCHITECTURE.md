# Architecture

The application targets Android and Windows using Flutter, with platform-specific adapters kept outside the domain layer.

- Presentation: responsive Flutter UI.
- Playback: just_audio queue and transport.
- Library: persistent local track metadata.
- Providers: capability-based provider contract; local files are the initial provider.
- Plugin host: manifest validation, compatibility, permissions, lifecycle and error isolation.
- Platform adapters: Android foreground media session and Windows system media integration.

## Milestone 0.1

Implemented in this commit: Flutter application foundation, local audio import, persisted library metadata, local search, liked-track persistence, queue-backed file playback, transport controls and responsive navigation.

Not implemented yet: remote streaming providers, signed third-party plugin execution, database migrations, background media sessions, authorized downloads, full playlist CRUD, Windows media integration and installer packaging. These must not be reported as complete until implemented and tested.

## Plugin runtime

Flutter cannot securely download and dynamically execute arbitrary Dart packages in a released application. Third-party plugins require a signed package format and sandbox runtime (planned WASM). Until that host exists, the app must not claim arbitrary third-party plugin installation.
