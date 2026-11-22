# Provider integrations

- **LRCLIB:** implemented plain and timestamped lyrics lookup. The client identifies itself and handles missing records and rate-limit responses.
- **Spotify metadata:** implemented using the official Web API. It requires a valid OAuth access token from the app's account-connection flow. Spotify metadata and artwork must retain attribution and links to Spotify.
- **YouTube Music metadata:** requires a maintained provider adapter and must not be shown as connected until implemented.
- **NewPipe YouTube audio:** requires the NewPipe Extractor integration in the Android native layer. It is not yet available in Windows. Resolving a playable stream is distinct from permission to save an offline copy.
- **Downloads:** a separate queue/storage service may save local files and media explicitly authorized for download. It must not rip Spotify streams or bypass DRM, access controls, or provider restrictions.

Do not mark an adapter installed merely because its manifest exists. Show implemented, needs account connection, or planned accurately.
