# Provider plugins

Silver Music automatically registers and installs its bundled provider modules on first launch:

- **Local music library** — scans Android MediaStore and the user's Music/Downloads folders on Windows.
- **Metadata support** — shared track metadata normalization used by the library.

The app persists installed module IDs and initializes them without a manual install step.

## Community plugins

The Spotube-style community plugin store is a separate feature. Silver Music does not currently execute arbitrary third-party plugin packages. A compatible sandbox runtime, package signature verification, permission mediation, and cross-platform lifecycle support are required before external plugins can be safely installed and run.

Do not treat a downloaded archive as an installed or executable plugin. Never bypass DRM, paywalls, authentication, or provider download restrictions. Offline downloads are allowed only where the provider explicitly supports them.
