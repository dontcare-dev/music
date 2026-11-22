import 'package:flutter_test/flutter_test.dart';
import 'package:silver_music/main.dart';

void main() {
  test('track metadata round trips', () {
    const track = Track(id: 'one', title: 'Example', path: '/music/example.mp3', artist: 'Artist');
    final restored = Track.fromMap(track.toMap());
    expect(restored.id, track.id);
    expect(restored.title, track.title);
    expect(restored.path, track.path);
    expect(restored.artist, track.artist);
  });
}
