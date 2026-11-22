import 'package:flutter_new_pipe_extractor/flutter_new_pipe_extractor.dart';

class NewPipeTrack {
  const NewPipeTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
    this.artwork,
    this.durationSeconds = 0,
  });

  final String id;
  final String title;
  final String artist;
  final String url;
  final String? artwork;
  final int durationSeconds;
}

class NewPipeProvider {
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await NewPipeExtractor.init();
    _initialized = true;
  }

  Future<List<NewPipeTrack>> search(String query) async {
    await initialize();
    final results = await NewPipeExtractor.search(
      query,
      contentFilters: [SearchContentFilters.musicSongs, SearchContentFilters.musicVideos],
    );
    return results.whereType<VideoSearchResultItem>().map((item) {
      final id = Uri.tryParse(item.url)?.queryParameters['v'] ??
          Uri.tryParse(item.url)?.pathSegments.last ??
          item.url;
      return NewPipeTrack(
        id: id,
        title: item.name,
        artist: item.uploaderName,
        url: item.url,
        artwork: item.thumbnails.isEmpty ? null : item.thumbnails.first.url,
        durationSeconds: item.duration,
      );
    }).toList();
  }

  Future<Uri> resolveAudio(String videoId) async {
    await initialize();
    final info = await NewPipeExtractor.getVideoInfo(videoId);
    final streams = info.audioStreams.toList()
      ..sort((a, b) => b.bitrate.compareTo(a.bitrate));
    if (streams.isEmpty) {
      throw Exception('No audio stream is available for this result.');
    }
    return Uri.parse(streams.first.content);
  }
}
