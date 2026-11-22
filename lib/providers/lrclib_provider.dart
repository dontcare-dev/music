import 'dart:convert';
import 'package:http/http.dart' as http;
import 'provider_models.dart';

class LrclibProvider {
  static const _base = 'https://lrclib.net/api';
  static const _agent = 'SilverMusic/0.2 (https://github.com/dontcare-dev/music)';

  Future<LyricsResult?> findLyrics({required String title, required String artist, String? album, Duration? duration}) async {
    final query = <String, String>{
      'track_name': title,
      'artist_name': artist,
      if (album != null && album.isNotEmpty) 'album_name': album,
      if (duration != null && duration.inSeconds > 0) 'duration': duration.inSeconds.toString(),
    };
    final response = await http.get(Uri.parse('$_base/get').replace(queryParameters: query), headers: {'User-Agent': _agent});
    if (response.statusCode == 404) return null;
    if (response.statusCode == 429) throw Exception('LRCLIB rate limit reached. Retry later.');
    if (response.statusCode != 200) throw Exception('LRCLIB request failed (' + response.statusCode.toString() + ').');
    return LyricsResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<LyricsResult>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await http.get(Uri.parse('$_base/search').replace(queryParameters: {'q': query.trim()}), headers: {'User-Agent': _agent});
    if (response.statusCode == 429) throw Exception('LRCLIB rate limit reached. Retry later.');
    if (response.statusCode != 200) throw Exception('LRCLIB search failed (' + response.statusCode.toString() + ').');
    final rows = jsonDecode(response.body) as List<dynamic>;
    return rows.whereType<Map<String, dynamic>>().map(LyricsResult.fromJson).toList();
  }
}
