import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() => runApp(const SilverMusicApp());

const accent = Color(0xFFB9A5FF);

class SilverMusicApp extends StatelessWidget {
  const SilverMusicApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Silver Music',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF09090E), colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark), useMaterial3: true),
    home: const MusicHome(),
  );
}

class Track {
  const Track({required this.id, required this.title, required this.path, this.artist = 'Unknown artist'});
  final String id, title, path, artist;
  Map<String, String> toMap() => {'id': id, 'title': title, 'path': path, 'artist': artist};
  factory Track.fromMap(Map<String, dynamic> m) => Track(id: m['id'], title: m['title'], path: m['path'], artist: m['artist'] ?? 'Unknown artist');
}

class MusicHome extends StatefulWidget {
  const MusicHome({super.key});
  @override
  State<MusicHome> createState() => _MusicHomeState();
}

class _MusicHomeState extends State<MusicHome> {
  final player = AudioPlayer();
  final tracks = <Track>[];
  final liked = <String>{};
  final tabs = const ['Home','Search','Explore','Playlists','Downloads','Local Music','Plugins','Settings'];
  int tab = 0, current = -1;
  bool busy = false;
  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    _restore();
    player.currentIndexStream.listen((i) { if (mounted && i != null) setState(() => current = i); });
    player.playerStateStream.listen((_) { if (mounted) setState(() {}); });
  }

  Future<void> _restore() async {
    prefs = await SharedPreferences.getInstance();
    tracks.addAll((prefs!.getStringList('tracks') ?? []).map((s) => Track.fromMap(Uri.splitQueryString(s))));
    liked.addAll(prefs!.getStringList('liked') ?? []);
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    await prefs?.setStringList('tracks', tracks.map((t) => Uri(queryParameters: t.toMap()).query).toList());
    await prefs?.setStringList('liked', liked.toList());
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true);
    if (result == null) return;
    for (final f in result.files) {
      if (f.path == null || tracks.any((t) => t.path == f.path)) continue;
      tracks.add(Track(id: const Uuid().v4(), title: f.name.replaceFirst(RegExp(r'\.[^.]+$'), ''), path: f.path!));
    }
    await _save();
    if (mounted) setState(() {});
  }

  Future<void> _play(int index) async {
    if (index < 0 || index >= tracks.length) return;
    try {
      setState(() => busy = true);
      await player.setAudioSources(tracks.map((t) => AudioSource.file(t.path, tag: t.title)).toList(), initialIndex: index);
      await player.play();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playback failed: $e')));
    } finally { if (mounted) setState(() => busy = false); }
  }

  @override
  void dispose() { player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Scaffold(body: Stack(children: [
      Positioned(top: -160, right: -100, child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70), child: Container(width: 340, height: 340, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x554A3C86))))),
      SafeArea(child: Row(children: [
        if (wide) _sidebar(),
        Expanded(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 14, 18, 10), child: Row(children: [
            if (!wide) const Icon(Icons.graphic_eq_rounded, color: accent),
            if (!wide) const SizedBox(width: 8),
            Text(tabs[tab], style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700)),
            const Spacer(),
            if (tab == 0 || tab == 5) IconButton(onPressed: _import, icon: const Icon(Icons.add_rounded)),
            IconButton(onPressed: () => setState(() => tab = 7), icon: const Icon(Icons.tune_rounded)),
          ])),
          Expanded(child: _page()),
          _miniPlayer(),
          if (!wide) _bottomNav(),
        ])),
      ])),
    ]));
  }

  Widget _sidebar() => Container(width: 220, margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(12), decoration: _glass(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Padding(padding: EdgeInsets.all(12), child: Row(children: [Icon(Icons.graphic_eq_rounded, color: accent, size: 25), SizedBox(width: 9), Text('SILVER MUSIC', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2))])),
    const SizedBox(height: 18),
    ...List.generate(tabs.length, (i) => ListTile(dense: true, selected: tab == i, selectedTileColor: accent.withValues(alpha: .14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), leading: Icon(_icons[i], color: tab == i ? accent : Colors.white60), title: Text(tabs[i]), onTap: () => setState(() => tab = i))),
    const Spacer(),
    Padding(padding: const EdgeInsets.all(12), child: Text('${tracks.length} local tracks', style: const TextStyle(color: Colors.white54))),
  ]));

  Widget _page() {
    if (tab == 0) return ListView(padding: const EdgeInsets.all(22), children: [
      Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [accent.withValues(alpha: .22), const Color(0xFF242237)]), border: Border.all(color: Colors.white12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('YOUR MUSIC, YOUR WAY', style: TextStyle(color: accent, letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12), const Text('A library that\ntravels with you.', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w700)),
        const SizedBox(height: 18), FilledButton.icon(onPressed: _import, icon: const Icon(Icons.library_add_rounded), label: const Text('Import music')),
      ])),
      const SizedBox(height: 26), _heading('Recently added', '${tracks.length} tracks'),
      if (tracks.isEmpty) _empty('Your library is empty', 'Import audio files stored on this device.')
      else ...tracks.take(8).toList().asMap().entries.map((e) => _track(e.value, tracks.indexOf(e.value))),
    ]);
    if (tab == 1) return _search();
    if (tab == 5) return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [Text('${tracks.length} tracks', style: const TextStyle(color: Colors.white54)), const Spacer(), FilledButton.tonalIcon(onPressed: _import, icon: const Icon(Icons.add), label: const Text('Import'))])),
      Expanded(child: tracks.isEmpty ? _empty('No local music', 'Import audio files to build your library.') : ListView(children: tracks.asMap().entries.map((e) => _track(e.value, e.key)).toList())),
    ]);
    if (tab == 6) return ListView(padding: const EdgeInsets.all(22), children: [
      const Text('Provider ecosystem', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), const Text('The local-file provider is built in. Remote providers require compliant plugins and supported access methods.', style: TextStyle(color: Colors.white60, height: 1.5)),
      _plugin('Local library', 'Built in · Available', true),
      _plugin('YouTube Music metadata', 'Not connected', false),
      _plugin('Spotify metadata', 'Not connected', false),
      _plugin('Third-party plugin runtime', 'SDK documented · Runtime pending', false),
    ]);
    final descriptions = {
      2: 'Connect a supported provider plugin to discover music.',
      3: 'Playlist creation and editing are part of the next library milestone.',
      4: 'Only provider-authorized downloadable files can be stored offline.',
      7: 'Playback and application preferences will appear here.',
    };
    return _empty(tabs[tab], descriptions[tab] ?? '');
  }

  Widget _search() => _Search(tracks: tracks, onPlay: _play);

  Widget _track(Track t, int i) => ListTile(
    leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF242432), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.music_note_rounded, color: accent)),
    title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text(t.artist, style: const TextStyle(color: Colors.white54)),
    trailing: IconButton(onPressed: () async { setState(() => liked.contains(t.id) ? liked.remove(t.id) : liked.add(t.id)); await _save(); }, icon: Icon(liked.contains(t.id) ? Icons.favorite : Icons.favorite_border, color: liked.contains(t.id) ? accent : Colors.white38)),
    onTap: () => _play(i),
  );

  Widget _plugin(String name, String state, bool active) => Container(margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(16), decoration: _glass(), child: Row(children: [
    const Icon(Icons.extension_rounded, color: accent, size: 25), const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w600)), Text(state, style: const TextStyle(color: Colors.white54, fontSize: 12))])),
    Text(active ? 'Operational' : 'Unavailable', style: TextStyle(color: active ? Colors.greenAccent : Colors.white54, fontSize: 11)),
  ]));

  Widget _heading(String title, String detail) => Row(children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Spacer(), Text(detail, style: const TextStyle(color: Colors.white38, fontSize: 12))]);

  Widget _empty(String title, String detail) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.library_music_outlined, size: 42, color: Colors.white30), const SizedBox(height: 14),
    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
    Text(detail, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, height: 1.5)),
  ])));

  Widget _miniPlayer() {
    if (current < 0 || current >= tracks.length) return const SizedBox(height: 6);
    final t = tracks[current];
    return Container(margin: const EdgeInsets.fromLTRB(12, 4, 12, 8), padding: const EdgeInsets.all(8), decoration: _glass(18), child: Column(children: [
      Row(children: [
        const Icon(Icons.album_rounded, color: accent, size: 34), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)), Text(t.artist, style: const TextStyle(color: Colors.white54, fontSize: 11))])),
        IconButton(onPressed: player.seekToPrevious, icon: const Icon(Icons.skip_previous_rounded)),
        IconButton(onPressed: busy ? null : () => player.playing ? player.pause() : player.play(), icon: Icon(player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28)),
        IconButton(onPressed: player.seekToNext, icon: const Icon(Icons.skip_next_rounded)),
      ]),
      StreamBuilder<Duration>(stream: player.positionStream, builder: (_, s) {
        final d = player.duration ?? Duration.zero, p = s.data ?? Duration.zero;
        return Slider(value: d.inMilliseconds == 0 ? 0 : p.inMilliseconds.clamp(0, d.inMilliseconds).toDouble(), max: d.inMilliseconds == 0 ? 1 : d.inMilliseconds.toDouble(), onChanged: (v) => player.seek(Duration(milliseconds: v.round())));
      }),
    ]));
  }

  Widget _bottomNav() => Container(margin: const EdgeInsets.fromLTRB(12, 0, 12, 10), decoration: _glass(18), child: NavigationBar(
    height: 64, backgroundColor: Colors.transparent, selectedIndex: [0,1,2,3,5].contains(tab) ? [0,1,2,3,5].indexOf(tab) : 0,
    onDestinationSelected: (i) => setState(() => tab = [0,1,2,3,5][i]),
    destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
      NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Explore'),
      NavigationDestination(icon: Icon(Icons.queue_music), label: 'Lists'),
      NavigationDestination(icon: Icon(Icons.library_music_outlined), label: 'Library'),
    ],
  ));

  BoxDecoration _glass([double radius = 18]) => BoxDecoration(color: Colors.white.withValues(alpha: .055), borderRadius: BorderRadius.circular(radius), border: Border.all(color: Colors.white.withValues(alpha: .09)));
  static const _icons = [Icons.home_rounded, Icons.search_rounded, Icons.explore_rounded, Icons.queue_music_rounded, Icons.download_rounded, Icons.library_music_rounded, Icons.extension_rounded, Icons.settings_rounded];
}

class _Search extends StatefulWidget {
  const _Search({required this.tracks, required this.onPlay});
  final List<Track> tracks;
  final ValueChanged<int> onPlay;
  @override
  State<_Search> createState() => _SearchState();
}
class _SearchState extends State<_Search> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final found = widget.tracks.where((t) => t.title.toLowerCase().contains(query.toLowerCase()) || t.artist.toLowerCase().contains(query.toLowerCase())).toList();
    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(hintText: 'Search your library', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white.withValues(alpha: .05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)))),
      Expanded(child: ListView(children: found.map((t) => ListTile(leading: const Icon(Icons.music_note, color: accent), title: Text(t.title), subtitle: Text(t.artist), onTap: () => widget.onPlay(widget.tracks.indexOf(t)))).toList())),
    ]);
  }
}
