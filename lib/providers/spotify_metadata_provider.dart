import 'dart:convert';
import 'package:http/http.dart' as http;
import 'provider_models.dart';

class SpotifyMetadataProvider {
  SpotifyMetadataProvider({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<List<ProviderTrack>> searchTracks({required String query, required String accessToken, String market = 'IN'}) async {
    if (query.trim().isEmpty) return [];
    if (accessToken.trim().isEmpty) throw ArgumentError('A Spotify OAuth access token is required.');
    final uri = Uri.https('api.spotify.com', '/v1/search', {'q': query.trim(), 'type': 'track', 'limit': '20', 'market': market});
    final response = await _client.get(uri, headers: {'Authorization': 'Bearer ' + accessToken});
    if (response.statusCode == 401) throw Exception('Spotify authorization expired. Reconnect Spotify.');
    if (response.statusCode == 403) throw Exception('Spotify denied this metadata request.');
    if (response.statusCode != 200) throw Exception('Spotify search failed (' + response.statusCode.toString() + ').');
    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final tracks = (root['tracks'] as Map<String, dynamic>)['items'] as List<dynamic>;
    return tracks.whereType<Map<String, dynamic>>().map((item) {
      final artists = (item['artists'] as List<dynamic>).whereType<Map<String, dynamic>>().map((a) => a['name'] as String? ?? '').where((name) => name.isNotEmpty).join(', ');
      final album = item['album'] as Map<String, dynamic>? ?? {};
      final images = album['images'] as List<dynamic>? ?? [];
      final artwork = images.isEmpty ? null : (images.first as Map<String, dynamic>)['url'] as String?;
      final urls = item['external_urls'] as Map<String, dynamic>? ?? {};
      return ProviderTrack(
        id: item['id'] as String? ?? '',
        title: item['name'] as String? ?? 'Unknown title',
        artist: artists.isEmpty ? 'Unknown artist' : artists,
        album: album['name'] as String? ?? '',
        artworkUrl: artwork,
        durationMs: item['duration_ms'] as int?,
        source: 'Spotify',
        externalUrl: urls['spotify'] as String?,
      );
    }).toList();
  }

  void dispose() => _client.close();
}
