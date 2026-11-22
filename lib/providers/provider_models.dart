class ProviderTrack {
  const ProviderTrack({required this.id, required this.title, required this.artist, this.album = '', this.artworkUrl, this.durationMs, this.source, this.externalUrl});
  final String id;
  final String title;
  final String artist;
  final String album;
  final String? artworkUrl;
  final int? durationMs;
  final String? source;
  final String? externalUrl;
}

class LyricsResult {
  const LyricsResult({required this.trackName, required this.artistName, this.plainLyrics, this.syncedLyrics, this.instrumental = false});
  final String trackName;
  final String artistName;
  final String? plainLyrics;
  final String? syncedLyrics;
  final bool instrumental;
  factory LyricsResult.fromJson(Map<String, dynamic> json) => LyricsResult(
    trackName: (json['trackName'] ?? json['name'] ?? '') as String,
    artistName: (json['artistName'] ?? '') as String,
    plainLyrics: json['plainLyrics'] as String?,
    syncedLyrics: json['syncedLyrics'] as String?,
    instrumental: json['instrumental'] == true,
  );
}
