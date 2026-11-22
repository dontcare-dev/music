import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() => runApp(const SilverMusicApp());

const bg = Color(0xFF101114);
const panel = Color(0xFF191B20);
const panel2 = Color(0xFF22252B);
const accent = Color(0xFFB6A0FF);
const muted = Color(0xFF9296A0);

class SilverMusicApp extends StatelessWidget {
  const SilverMusicApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Silver Music',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: bg,
          colorScheme: const ColorScheme.dark(
            primary: accent,
            surface: panel,
            onSurface: Colors.white,
          ),
          fontFamily: 'Inter',
          useMaterial3: true,
        ),
        home: const MusicHome(),
      );
}

class SIcon extends StatelessWidget {
  const SIcon(this.name, {super.key, this.size = 20, this.color = Colors.white});
  final String name;
  final double size;
  final Color color;

  static const paths = <String, String>{
    'home': 'M3 10.5 12 3l9 7.5V21h-6v-6H9v6H3z',
    'search': 'M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm6-2 4 4',
    'library': 'M4 4v16M9 4v16M14 5l4-1 3 15-4 1z',
    'list': 'M4 6h16M4 12h16M4 18h16',
    'plug': 'M8 3v5m8-5v5M6 8h12v4a6 6 0 0 1-12 0zM12 18v3',
    'settings': 'M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8Zm0-5v2m0 14v2M4.9 4.9l1.4 1.4m11.4 11.4 1.4 1.4M3 12h2m14 0h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4',
    'play': 'm8 5 11 7-11 7z',
    'pause': 'M7 5h3v14H7zM14 5h3v14h-3z',
    'next': 'm5 5 10 7-10 7zM18 5v14',
    'prev': 'm19 5-10 7 10 7zM6 5v14',
    'heart': 'M20.8 8.8c0 5.2-8.8 11-8.8 11S3.2 14 3.2 8.8A4.8 4.8 0 0 1 12 6.1a4.8 4.8 0 0 1 8.8 2.7Z',
    'refresh': 'M20 7v5h-5M4 17v-5h5M5.6 9A7 7 0 0 1 18 6l2 6M4 12l2 6a7 7 0 0 0 12.4-3',
    'plus': 'M12 5v14M5 12h14',
    'more': 'M5 12h.01M12 12h.01M19 12h.01',
    'music': 'M9 18V5l12-2v13M9 18a3 3 0 1 1-3-3c1.7 0 3 1.3 3 3Zm12-2a3 3 0 1 1-3-3c1.7 0 3 1.3 3 3Z',
    'folder': 'M3 6h7l2 2h9v11H3z',
    'close': 'M6 6l12 12M18 6 6 18',
  };

  @override
  Widget build(BuildContext context) {
    final d = paths[name] ?? paths['music']!;
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="$d" fill="none" stroke="#${color.value.toRadixString(16).substring(2)}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>',
      width: size,
      height: size,
    );
  }
}

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.path,
    this.artist = 'Unknown artist',
    this.album = '',
  });

  final String id;
  final String title;
  final String path;
  final String artist;
  final String album;

  Map<String, String> toMap() => {
        'id': id,
        'title': title,
        'path': path,
        'artist': artist,
        'album': album,
      };

  factory Track.fromMap(Map<String, dynamic> map) => Track(
        id: map['id'] as String,
        title: map['title'] as String,
        path: map['path'] as String,
        artist: (map['artist'] as String?) ?? 'Unknown artist',
        album: (map['album'] as String?) ?? '',
      );
}

class BuiltinPlugin {
  const BuiltinPlugin({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
  });

  final String id;
  final String name;
  final String description;
  final String version;
}

class MetadataPlugin {
  static String title(String value) {
    final cleaned = value.trim();
    return cleaned.isEmpty ? 'Unknown title' : cleaned;
  }

  static String artist(String? value) {
    final cleaned = value?.trim() ?? '';
    return cleaned.isEmpty ? 'Unknown artist' : cleaned;
  }

  static String fileTitle(String value) {
    final dot = value.lastIndexOf('.');
    return title(dot > 0 ? value.substring(0, dot) : value);
  }
}

class PluginManager {
  static const bundled = <BuiltinPlugin>[
    BuiltinPlugin(
      id: 'silver.local-library',
      name: 'Local music library',
      description: 'Scans music stored on this device and keeps the library updated.',
      version: '1.0.0',
    ),
    BuiltinPlugin(
      id: 'silver.metadata-core',
      name: 'Metadata support',
      description: 'Normalizes track titles, artists and album information.',
      version: '1.0.0',
    ),
  ];

  Future<List<String>> autoInstall(SharedPreferences prefs) async {
    final installed = (prefs.getStringList('installed_plugins') ?? <String>[]).toSet();
    for (final plugin in bundled) {
      installed.add(plugin.id);
    }
    final result = installed.toList()..sort();
    await prefs.setStringList('installed_plugins', result);
    return result;
  }
}

class MusicHome extends StatefulWidget {
  const MusicHome({super.key});

  @override
  State<MusicHome> createState() => _MusicHomeState();
}

class _MusicHomeState extends State<MusicHome> {
  final player = AudioPlayer();
  final audioQuery = OnAudioQuery();
  final tracks = <Track>[];
  final liked = <String>{};
  final searchController = TextEditingController();
  SharedPreferences? prefs;
  List<String> installedPlugins = [];
  int tab = 0;
  int current = -1;
  bool busy = false;
  bool scanning = true;
  String scanMessage = 'Checking your music library';

  static const tabs = [
    ('Home', 'home'),
    ('Search', 'search'),
    ('Your library', 'library'),
    ('Playlists', 'list'),
    ('Plugins', 'plug'),
    ('Settings', 'settings'),
  ];

  @override
  void initState() {
    super.initState();
    player.currentIndexStream.listen((index) {
      if (mounted && index != null) setState(() => current = index);
    });
    player.playerStateStream.listen((_) {
      if (mounted) setState(() {});
    });
    _initialize();
  }

  Future<void> _initialize() async {
    prefs = await SharedPreferences.getInstance();
    tracks.addAll((prefs!.getStringList('tracks') ?? []).map(
      (value) => Track.fromMap(Uri.splitQueryString(value)),
    ));
    liked.addAll(prefs!.getStringList('liked') ?? []);
    installedPlugins = await PluginManager().autoInstall(prefs!);
    if (mounted) setState(() {});
    await _scanLibrary(silent: true);
  }

  Future<void> _save() async {
    await prefs?.setStringList(
      'tracks',
      tracks.map((track) => Uri(queryParameters: track.toMap()).query).toList(),
    );
    await prefs?.setStringList('liked', liked.toList());
  }

  bool _isAudio(String path) {
    final ext = path.toLowerCase().split('.').last;
    return const {'mp3', 'm4a', 'aac', 'flac', 'ogg', 'opus', 'wav', 'wma', 'aiff'}
        .contains(ext);
  }

  Future<void> _scanLibrary({bool silent = false}) async {
    if (scanning && !silent) return;
    if (mounted) setState(() {
      scanning = true;
      scanMessage = 'Scanning device storage';
    });

    try {
      final found = <Track>[];
      if (Platform.isAndroid) {
        final allowed = await audioQuery.checkAndRequest(retryRequest: true);
        if (!allowed) {
          scanMessage = 'Allow audio access to scan music on this device.';
        } else {
          final songs = await audioQuery.querySongs(
            sortType: SongSortType.TITLE,
            orderType: OrderType.ASC_OR_SMALLER,
            uriType: UriType.EXTERNAL,
            ignoreCase: true,
          );
          for (final song in songs) {
            if (song.data.isEmpty) continue;
            found.add(Track(
              id: 'android-${song.id}',
              title: MetadataPlugin.title(song.title),
              artist: MetadataPlugin.artist(song.artist),
              album: song.album ?? '',
              path: song.data,
            ));
          }
        }
      } else if (Platform.isWindows) {
        final root = Platform.environment['USERPROFILE'];
        if (root != null) {
          for (final folder in ['Music', 'Downloads']) {
            final directory = Directory('$root\\$folder');
            if (!await directory.exists()) continue;
            await for (final entity in directory.list(recursive: true, followLinks: false)) {
              if (entity is File && _isAudio(entity.path)) {
                final name = entity.uri.pathSegments.isEmpty
                    ? entity.path.split(Platform.pathSeparator).last
                    : entity.uri.pathSegments.last;
                found.add(Track(
                  id: entity.path.toLowerCase(),
                  title: name.replaceFirst(RegExp(r'\.[^.]+$'), ''),
                  path: entity.path,
                ));
                if (found.length >= 10000) break;
              }
            }
          }
        }
      }

      if (found.isNotEmpty) {
        final paths = tracks.map((track) => track.path).toSet();
        for (final track in found) {
          if (paths.add(track.path)) tracks.add(track);
        }
        tracks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        await _save();
        scanMessage = '${tracks.length} tracks found';
      } else if (Platform.isAndroid && scanMessage.startsWith('Allow')) {
        // Permission guidance is shown in the library view.
      } else {
        scanMessage = 'No audio files found in Music or Downloads.';
      }
    } catch (error) {
      scanMessage = 'Library scan could not finish: $error';
    } finally {
      if (mounted) setState(() => scanning = false);
    }
  }

  Future<void> _importFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );
    if (result == null) return;
    final existing = tracks.map((track) => track.path).toSet();
    for (final file in result.files) {
      final path = file.path;
      if (path == null || !existing.add(path)) continue;
      tracks.add(Track(
        id: const Uuid().v4(),
        title: MetadataPlugin.fileTitle(file.name),
        path: path,
      ));
    }
    tracks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    await _save();
    if (mounted) setState(() {});
  }

  Future<void> _play(int index) async {
    if (index < 0 || index >= tracks.length) return;
    try {
      setState(() => busy = true);
      await player.setAudioSource(
        ConcatenatingAudioSource(
          children: tracks.map((track) => AudioSource.file(track.path, tag: track.title)).toList(),
        ),
        initialIndex: index,
      );
      await player.play();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to play this track: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _toggleLike(Track track) async {
    setState(() {
      if (!liked.add(track.id)) liked.remove(track.id);
    });
    await _save();
  }

  @override
  void dispose() {
    searchController.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 820;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide) _sidebar(),
            Expanded(
              child: Column(
                children: [
                  _topBar(wide),
                  Expanded(child: _page()),
                  _playerBar(),
                  if (!wide) _mobileNav(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebar() => Container(
        width: 224,
        margin: const EdgeInsets.fromLTRB(14, 14, 0, 14),
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .055)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 4, 12, 28),
              child: Row(
                children: [
                  SIcon('music', color: accent, size: 24),
                  SizedBox(width: 10),
                  Text('SILVER MUSIC', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text('LIBRARY', style: TextStyle(fontSize: 10, color: muted, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
            ),
            ...List.generate(5, (index) => _navItem(index)),
            const Spacer(),
            _navItem(5),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('${tracks.length} tracks on this device', style: const TextStyle(color: muted, fontSize: 11)),
            ),
          ],
        ),
      );

  Widget _navItem(int index) {
    final selected = tab == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: .13) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SIcon(tabs[index].$2, size: 18, color: selected ? accent : muted),
              const SizedBox(width: 12),
              Text(tabs[index].$1, style: TextStyle(color: selected ? Colors.white : const Color(0xFFB9BBC2), fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(bool wide) => Padding(
        padding: EdgeInsets.fromLTRB(wide ? 28 : 18, 22, 18, 18),
        child: Row(
          children: [
            if (!wide) const SIcon('music', color: accent, size: 21),
            if (!wide) const SizedBox(width: 10),
            Text(tabs[tab].$1, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -.4)),
            const Spacer(),
            if (tab == 2)
              IconButton(
                tooltip: 'Scan music again',
                onPressed: scanning ? null : _scanLibrary,
                icon: const SIcon('refresh', color: muted),
              ),
            if (tab == 0 || tab == 2)
              IconButton(
                tooltip: 'Add audio files',
                onPressed: _importFiles,
                icon: const SIcon('plus', color: Colors.white),
              ),
          ],
        ),
      );

  Widget _page() {
    if (tab == 0) return _homePage();
    if (tab == 1) return _searchPage();
    if (tab == 2) return _libraryPage();
    if (tab == 3) return _playlistsPage();
    if (tab == 4) return _pluginsPage();
    return _settingsPage();
  }

  Widget _homePage() => ListView(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF24212F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF383345)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('YOUR COLLECTION', style: TextStyle(color: accent, fontSize: 10, letterSpacing: 1.6, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      const Text('All your music.\nIn one place.', style: TextStyle(fontSize: 27, height: 1.18, fontWeight: FontWeight.w700, letterSpacing: -.7)),
                      const SizedBox(height: 18),
                      Text('${tracks.length} tracks · ${liked.length} liked', style: const TextStyle(color: Color(0xFFB8B2C6), fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(color: const Color(0xFF39334A), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: SIcon('music', color: accent, size: 38)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _sectionTitle('Recently added', 'YOUR DEVICE'),
          const SizedBox(height: 10),
          if (tracks.isEmpty)
            _emptyLibrary()
          else
            ...tracks.take(8).map((track) => _trackTile(track, tracks.indexOf(track))),
        ],
      );

  Widget _libraryPage() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
            child: Row(
              children: [
                Text('${tracks.length} tracks', style: const TextStyle(color: muted, fontSize: 12)),
                const Spacer(),
                if (scanning) const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 1.5)),
                const SizedBox(width: 8),
                TextButton(onPressed: scanning ? null : _scanLibrary, child: const Text('Rescan')),
                TextButton(onPressed: _importFiles, child: const Text('Add files')),
              ],
            ),
          ),
          if (tracks.isEmpty)
            Expanded(child: _emptyLibrary())
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: tracks.length,
                itemBuilder: (_, index) => _trackTile(tracks[index], index),
              ),
            ),
        ],
      );

  Widget _emptyLibrary() => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SIcon('folder', size: 38, color: muted),
              const SizedBox(height: 18),
              const Text('No music found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                scanning ? scanMessage : scanMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted, height: 1.5, fontSize: 12),
              ),
              const SizedBox(height: 18),
              OutlinedButton(onPressed: scanning ? null : _scanLibrary, child: const Text('Scan device')),
              TextButton(onPressed: _importFiles, child: const Text('Choose audio files')),
            ],
          ),
        ),
      );

  Widget _searchPage() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search songs or artists',
                hintStyle: const TextStyle(color: muted, fontSize: 13),
                prefixIcon: const Padding(padding: EdgeInsets.all(14), child: SIcon('search', color: muted, size: 17)),
                filled: true,
                fillColor: panel,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: Builder(builder: (_) {
              final query = searchController.text.toLowerCase().trim();
              final found = tracks.where((track) =>
                track.title.toLowerCase().contains(query) ||
                track.artist.toLowerCase().contains(query) ||
                track.album.toLowerCase().contains(query)).toList();
              if (found.isEmpty) return const Center(child: Text('No matching tracks', style: TextStyle(color: muted)));
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: found.map((track) => _trackTile(track, tracks.indexOf(track))).toList(),
              );
            }),
          ),
        ],
      );

  Widget _trackTile(Track track, int index) {
    final active = current == index;
    final isLiked = liked.contains(track.id);
    return InkWell(
      onTap: () => _play(index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(color: active ? const Color(0xFF39314F) : panel2, borderRadius: BorderRadius.circular(7)),
              child: Center(child: SIcon('music', size: 19, color: active ? accent : muted)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? accent : Colors.white)),
                  const SizedBox(height: 4),
                  Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: muted)),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => _toggleLike(track),
              icon: SIcon('heart', size: 17, color: isLiked ? accent : muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playlistsPage() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SIcon('list', color: muted, size: 34),
              const SizedBox(height: 14),
              const Text('Playlists', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 7),
              const Text('Playlist management is being built next.', style: TextStyle(color: muted, fontSize: 12)),
            ],
          ),
        ),
      );

  Widget _pluginsPage() => ListView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        children: [
          const Text('Installed automatically', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Silver Music installs its bundled providers on first launch.', style: TextStyle(color: muted, fontSize: 12, height: 1.5)),
          const SizedBox(height: 18),
          ...PluginManager.bundled.map((plugin) {
            final installed = installedPlugins.contains(plugin.id);
            return Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.white.withValues(alpha: .055))),
              child: Row(
                children: [
                  const SIcon('plug', color: accent, size: 21),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plugin.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(plugin.description, style: const TextStyle(color: muted, fontSize: 11, height: 1.4)),
                        const SizedBox(height: 5),
                        Text('v${plugin.version}', style: const TextStyle(color: muted, fontSize: 10)),
                      ],
                    ),
                  ),
                  Text(installed ? 'INSTALLED' : 'PENDING', style: TextStyle(color: installed ? const Color(0xFF8DD8A8) : muted, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          const Text('Community plugin execution is not enabled yet. Plugins need a verified sandbox runtime before third-party code can be installed and run safely.', style: TextStyle(color: muted, fontSize: 11, height: 1.5)),
        ],
      );

  Widget _settingsPage() => ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text('Library', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _settingRow('Automatic library scan', 'Scans music folders when the app starts', true),
          _settingRow('Installed providers', '${installedPlugins.length} bundled plugins', false),
          _settingRow('Local tracks', '${tracks.length} tracks indexed', false),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: scanning ? null : _scanLibrary, child: const Text('Rescan music folders')),
        ],
      );

  Widget _settingRow(String title, String subtitle, bool enabled) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF292B31)))),
        child: Row(
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: muted)),
            ])),
            if (enabled) const SIcon('refresh', color: accent, size: 17),
          ],
        ),
      );

  Widget _sectionTitle(String title, String detail) => Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(detail, style: const TextStyle(fontSize: 9, color: muted, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        ],
      );

  Widget _playerBar() {
    if (current < 0 || current >= tracks.length) return const SizedBox(height: 5);
    final track = tracks[current];
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 4),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: .06))),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 39, height: 39, decoration: BoxDecoration(color: panel2, borderRadius: BorderRadius.circular(6)), child: const Center(child: SIcon('music', color: accent, size: 18))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: muted)),
              ])),
              IconButton(visualDensity: VisualDensity.compact, onPressed: player.seekToPrevious, icon: const SIcon('prev', size: 18)),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: busy ? null : () => player.playing ? player.pause() : player.play(),
                icon: SIcon(player.playing ? 'pause' : 'play', size: 21, color: Colors.white),
              ),
              IconButton(visualDensity: VisualDensity.compact, onPressed: player.seekToNext, icon: const SIcon('next', size: 18)),
            ],
          ),
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (_, snapshot) {
              final duration = player.duration ?? Duration.zero;
              final position = snapshot.data ?? Duration.zero;
              final max = duration.inMilliseconds.toDouble();
              return SliderTheme(
                data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4), overlayShape: SliderComponentShape.noOverlay),
                child: Slider(
                  value: max <= 0 ? 0 : position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
                  max: max <= 0 ? 1 : max,
                  onChanged: max <= 0 ? null : (value) => player.seek(Duration(milliseconds: value.round())),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _mobileNav() => Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 9),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [0, 1, 2, 3, 4].map((index) {
            final selected = tab == index;
            return InkWell(
              onTap: () => setState(() => tab = index),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SIcon(tabs[index].$2, size: 18, color: selected ? accent : muted),
                    const SizedBox(height: 4),
                    Text(
                      ['Home', 'Search', 'Library', 'Lists', 'Plugins'][index],
                      style: TextStyle(fontSize: 9, color: selected ? Colors.white : muted),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
}
), '')),
        path: path,
      ));
    }
    tracks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    await _save();
    if (mounted) setState(() {});
  }

  Future<void> _play(int index) async {
    if (index < 0 || index >= tracks.length) return;
    try {
      setState(() => busy = true);
      await player.setAudioSource(
        ConcatenatingAudioSource(
          children: tracks.map((track) => AudioSource.file(track.path, tag: track.title)).toList(),
        ),
        initialIndex: index,
      );
      await player.play();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to play this track: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _toggleLike(Track track) async {
    setState(() {
      if (!liked.add(track.id)) liked.remove(track.id);
    });
    await _save();
  }

  @override
  void dispose() {
    searchController.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 820;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide) _sidebar(),
            Expanded(
              child: Column(
                children: [
                  _topBar(wide),
                  Expanded(child: _page()),
                  _playerBar(),
                  if (!wide) _mobileNav(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebar() => Container(
        width: 224,
        margin: const EdgeInsets.fromLTRB(14, 14, 0, 14),
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .055)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 4, 12, 28),
              child: Row(
                children: [
                  SIcon('music', color: accent, size: 24),
                  SizedBox(width: 10),
                  Text('SILVER MUSIC', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text('LIBRARY', style: TextStyle(fontSize: 10, color: muted, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
            ),
            ...List.generate(5, (index) => _navItem(index)),
            const Spacer(),
            _navItem(5),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('${tracks.length} tracks on this device', style: const TextStyle(color: muted, fontSize: 11)),
            ),
          ],
        ),
      );

  Widget _navItem(int index) {
    final selected = tab == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: .13) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SIcon(tabs[index].$2, size: 18, color: selected ? accent : muted),
              const SizedBox(width: 12),
              Text(tabs[index].$1, style: TextStyle(color: selected ? Colors.white : const Color(0xFFB9BBC2), fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(bool wide) => Padding(
        padding: EdgeInsets.fromLTRB(wide ? 28 : 18, 22, 18, 18),
        child: Row(
          children: [
            if (!wide) const SIcon('music', color: accent, size: 21),
            if (!wide) const SizedBox(width: 10),
            Text(tabs[tab].$1, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -.4)),
            const Spacer(),
            if (tab == 2)
              IconButton(
                tooltip: 'Scan music again',
                onPressed: scanning ? null : _scanLibrary,
                icon: const SIcon('refresh', color: muted),
              ),
            if (tab == 0 || tab == 2)
              IconButton(
                tooltip: 'Add audio files',
                onPressed: _importFiles,
                icon: const SIcon('plus', color: Colors.white),
              ),
          ],
        ),
      );

  Widget _page() {
    if (tab == 0) return _homePage();
    if (tab == 1) return _searchPage();
    if (tab == 2) return _libraryPage();
    if (tab == 3) return _playlistsPage();
    if (tab == 4) return _pluginsPage();
    return _settingsPage();
  }

  Widget _homePage() => ListView(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF24212F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF383345)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('YOUR COLLECTION', style: TextStyle(color: accent, fontSize: 10, letterSpacing: 1.6, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      const Text('All your music.\nIn one place.', style: TextStyle(fontSize: 27, height: 1.18, fontWeight: FontWeight.w700, letterSpacing: -.7)),
                      const SizedBox(height: 18),
                      Text('${tracks.length} tracks · ${liked.length} liked', style: const TextStyle(color: Color(0xFFB8B2C6), fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(color: const Color(0xFF39334A), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: SIcon('music', color: accent, size: 38)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _sectionTitle('Recently added', 'YOUR DEVICE'),
          const SizedBox(height: 10),
          if (tracks.isEmpty)
            _emptyLibrary()
          else
            ...tracks.take(8).map((track) => _trackTile(track, tracks.indexOf(track))),
        ],
      );

  Widget _libraryPage() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
            child: Row(
              children: [
                Text('${tracks.length} tracks', style: const TextStyle(color: muted, fontSize: 12)),
                const Spacer(),
                if (scanning) const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 1.5)),
                const SizedBox(width: 8),
                TextButton(onPressed: scanning ? null : _scanLibrary, child: const Text('Rescan')),
                TextButton(onPressed: _importFiles, child: const Text('Add files')),
              ],
            ),
          ),
          if (tracks.isEmpty)
            Expanded(child: _emptyLibrary())
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: tracks.length,
                itemBuilder: (_, index) => _trackTile(tracks[index], index),
              ),
            ),
        ],
      );

  Widget _emptyLibrary() => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SIcon('folder', size: 38, color: muted),
              const SizedBox(height: 18),
              const Text('No music found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                scanning ? scanMessage : scanMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted, height: 1.5, fontSize: 12),
              ),
              const SizedBox(height: 18),
              OutlinedButton(onPressed: scanning ? null : _scanLibrary, child: const Text('Scan device')),
              TextButton(onPressed: _importFiles, child: const Text('Choose audio files')),
            ],
          ),
        ),
      );

  Widget _searchPage() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search songs or artists',
                hintStyle: const TextStyle(color: muted, fontSize: 13),
                prefixIcon: const Padding(padding: EdgeInsets.all(14), child: SIcon('search', color: muted, size: 17)),
                filled: true,
                fillColor: panel,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: Builder(builder: (_) {
              final query = searchController.text.toLowerCase().trim();
              final found = tracks.where((track) =>
                track.title.toLowerCase().contains(query) ||
                track.artist.toLowerCase().contains(query) ||
                track.album.toLowerCase().contains(query)).toList();
              if (found.isEmpty) return const Center(child: Text('No matching tracks', style: TextStyle(color: muted)));
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: found.map((track) => _trackTile(track, tracks.indexOf(track))).toList(),
              );
            }),
          ),
        ],
      );

  Widget _trackTile(Track track, int index) {
    final active = current == index;
    final isLiked = liked.contains(track.id);
    return InkWell(
      onTap: () => _play(index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(color: active ? const Color(0xFF39314F) : panel2, borderRadius: BorderRadius.circular(7)),
              child: Center(child: SIcon('music', size: 19, color: active ? accent : muted)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? accent : Colors.white)),
                  const SizedBox(height: 4),
                  Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: muted)),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => _toggleLike(track),
              icon: SIcon('heart', size: 17, color: isLiked ? accent : muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playlistsPage() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SIcon('list', color: muted, size: 34),
              const SizedBox(height: 14),
              const Text('Playlists', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 7),
              const Text('Playlist management is being built next.', style: TextStyle(color: muted, fontSize: 12)),
            ],
          ),
        ),
      );

  Widget _pluginsPage() => ListView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        children: [
          const Text('Installed automatically', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Silver Music installs its bundled providers on first launch.', style: TextStyle(color: muted, fontSize: 12, height: 1.5)),
          const SizedBox(height: 18),
          ...PluginManager.bundled.map((plugin) {
            final installed = installedPlugins.contains(plugin.id);
            return Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.white.withValues(alpha: .055))),
              child: Row(
                children: [
                  const SIcon('plug', color: accent, size: 21),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plugin.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(plugin.description, style: const TextStyle(color: muted, fontSize: 11, height: 1.4)),
                        const SizedBox(height: 5),
                        Text('v${plugin.version}', style: const TextStyle(color: muted, fontSize: 10)),
                      ],
                    ),
                  ),
                  Text(installed ? 'INSTALLED' : 'PENDING', style: TextStyle(color: installed ? const Color(0xFF8DD8A8) : muted, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          const Text('Community plugin execution is not enabled yet. Plugins need a verified sandbox runtime before third-party code can be installed and run safely.', style: TextStyle(color: muted, fontSize: 11, height: 1.5)),
        ],
      );

  Widget _settingsPage() => ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text('Library', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _settingRow('Automatic library scan', 'Scans music folders when the app starts', true),
          _settingRow('Installed providers', '${installedPlugins.length} bundled plugins', false),
          _settingRow('Local tracks', '${tracks.length} tracks indexed', false),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: scanning ? null : _scanLibrary, child: const Text('Rescan music folders')),
        ],
      );

  Widget _settingRow(String title, String subtitle, bool enabled) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF292B31)))),
        child: Row(
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: muted)),
            ])),
            if (enabled) const SIcon('refresh', color: accent, size: 17),
          ],
        ),
      );

  Widget _sectionTitle(String title, String detail) => Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(detail, style: const TextStyle(fontSize: 9, color: muted, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        ],
      );

  Widget _playerBar() {
    if (current < 0 || current >= tracks.length) return const SizedBox(height: 5);
    final track = tracks[current];
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 4),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: .06))),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 39, height: 39, decoration: BoxDecoration(color: panel2, borderRadius: BorderRadius.circular(6)), child: const Center(child: SIcon('music', color: accent, size: 18))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: muted)),
              ])),
              IconButton(visualDensity: VisualDensity.compact, onPressed: player.seekToPrevious, icon: const SIcon('prev', size: 18)),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: busy ? null : () => player.playing ? player.pause() : player.play(),
                icon: SIcon(player.playing ? 'pause' : 'play', size: 21, color: Colors.white),
              ),
              IconButton(visualDensity: VisualDensity.compact, onPressed: player.seekToNext, icon: const SIcon('next', size: 18)),
            ],
          ),
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (_, snapshot) {
              final duration = player.duration ?? Duration.zero;
              final position = snapshot.data ?? Duration.zero;
              final max = duration.inMilliseconds.toDouble();
              return SliderTheme(
                data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4), overlayShape: SliderComponentShape.noOverlay),
                child: Slider(
                  value: max <= 0 ? 0 : position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
                  max: max <= 0 ? 1 : max,
                  onChanged: max <= 0 ? null : (value) => player.seek(Duration(milliseconds: value.round())),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _mobileNav() => Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 9),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [0, 1, 2, 3, 4].map((index) {
            final selected = tab == index;
            return InkWell(
              onTap: () => setState(() => tab = index),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SIcon(tabs[index].$2, size: 18, color: selected ? accent : muted),
                    const SizedBox(height: 4),
                    Text(
                      ['Home', 'Search', 'Library', 'Lists', 'Plugins'][index],
                      style: TextStyle(fontSize: 9, color: selected ? Colors.white : muted),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
}
