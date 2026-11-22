# Silver Music Provider SDK v1 draft

## Manifest

```json
{
  "schema": 1,
  "id": "org.example.provider",
  "name": "Example Provider",
  "version": "1.0.0",
  "apiVersion": "^1.0.0",
  "description": "Example metadata and playback provider",
  "entrypoint": "plugin.wasm",
  "permissions": ["catalog.search", "catalog.metadata", "playback.resolve"],
  "capabilities": ["search", "track", "artist", "album", "playlist", "stream"]
}
```

## Operations

Required: initialize(configuration), search(query, categories), getTrack(id), getArtist(id), getAlbum(id), getPlaylist(id), resolvePlayback(id, quality), dispose().

Optional: browse(), getArtwork(id), download(id, destination) only when provider-authorized, refreshAuthentication().

## Security

- Validate schema and API compatibility.
- Verify signatures and package hashes before installation.
- Require explicit consent for declared permissions.
- Execute in a restricted WASM runtime with no ambient filesystem/network access.
- Grant scoped host imports only.
- Apply timeouts, memory limits and crash isolation.
- Never expose application secrets.
- Store credentials in platform secure storage.
- Show identity, version, permissions and status before enabling.
- Revoke permissions on uninstall.

The signed installer and WASM runtime are future work; this document is a contract, not an implemented plugin store.
