import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/content_item.dart';
import '../services/screen2_video_service.dart';

class TopBarVideoPlayer extends StatefulWidget {
  const TopBarVideoPlayer({super.key});

  @override
  State<TopBarVideoPlayer> createState() => _TopBarVideoPlayerState();
}

class _TopBarVideoPlayerState extends State<TopBarVideoPlayer> {
  final _service = Screen2VideoService();
  List<ContentItem> _items = [];
  int _currentIndex = 0;
  Player? _player;
  VideoController? _controller;
  StreamSubscription? _completedSub;

  @override
  void initState() {
    super.initState();
    _loadService();
  }

  Future<void> _loadService() async {
    await _service.load();
    if (!mounted) return;
    setState(() => _items = List.from(_service.items));
    if (_items.isNotEmpty) _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    _completedSub?.cancel();
    _completedSub = null;
    await _player?.dispose();
    _player = null;
    _controller = null;

    if (_items.isEmpty) return;
    final item = _items[_currentIndex];

    if (item.type == ContentType.video) {
      if (kIsWeb && item.webUrl == null) return;
      if (!kIsWeb && item.path.isEmpty) return;

      _player = Player();
      _controller = VideoController(_player!);

      final shouldLoop = _items.length == 1;
      if (!shouldLoop) {
        _completedSub = _player!.stream.completed.listen((done) {
          if (done && mounted) _next();
        });
      }

      Media media;
      if (kIsWeb) {
        media = Media(item.webUrl!);
      } else if (item.path.startsWith('assets/')) {
        media = Media('asset:///${item.path}');
      } else {
        media = Media(item.path);
      }

      await _player!.open(media);
      if (shouldLoop) await _player!.setPlaylistMode(PlaylistMode.loop);
      await _player!.play();
      if (mounted) setState(() {});
    }
  }

  void _next() {
    if (_items.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _items.length;
    _loadCurrent();
  }

  @override
  void dispose() {
    _completedSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Container(
        color: const Color(0xFF050516),
        child: const Center(
          child: Icon(Icons.tv, color: Color(0xFF333366), size: 48),
        ),
      );
    }

    if (_controller != null) {
      return ClipRect(
        child: SizedBox.expand(
          child: Video(
            controller: _controller!,
            fit: BoxFit.cover,
            fill: Colors.black,
          ),
        ),
      );
    }

    return Container(color: Colors.black);
  }
}
