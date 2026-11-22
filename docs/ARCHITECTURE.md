# Architecture

The application targets Android and Windows using Flutter, with platform-specific adapters kept outside the domain layer.

- Presentation: responsive Flutter UI.
- Playback: just_audio queue and transport.
- Library: persistent local track metadata.
- Providers: capability-based provider contract; local files are the initial provider.
- Plugin host: manifest validation, compatibility, permissions, lifecycle and error isolation.
- Platform adapters: Android foreground media session and Windows system media integration.

## Milestone 0.1

Implemented: responsive Android/Windows UI, SVG-only navigation and controls, automatic Android MediaStore scanning, Windows Music/Downloads folder scanning, manual audio import fallback, persisted library metadata, local search, liked-track persistence, queue-backed playback, transport controls, and first-launch installation of bundled provider modules.

Still not implemented: third-party .smplug execution, remote streaming providers, database migrations, background media sessions, authorized downloads, full playlist CRUD, Windows system media integration, and installer packaging. Bundled modules are installed automatically; external plugin execution must wait for a verified cross-platform sandbox runtime.

## Plugin runtime

Flutter cannot securely download and dynamically execute arbitrary Dart packages in a released application. Third-party plugins require a signed package format and sandbox runtime (planned WASM). Until that host exists, the app must not claim arbitrary third-party plugin installation.
