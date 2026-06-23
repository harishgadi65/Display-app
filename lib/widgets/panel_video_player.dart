import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/content_item.dart';
import '../services/panel_video_service.dart';

class PanelVideoPlayer extends StatefulWidget {
  final PanelVideoService service;

  const PanelVideoPlayer({super.key, required this.service});

  @override
  State<PanelVideoPlayer> createState() => _PanelVideoPlayerState();
}

class _PanelVideoPlayerState extends State<PanelVideoPlayer> {
  List<ContentItem> _items = [];
  int _currentIndex = 0;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _loadService();
  }

  Future<void> _loadService() async {
    await widget.service.load();
    if (!mounted) return;
    setState(() => _items = List.from(widget.service.items));
    if (_items.isNotEmpty) _loadCurrent();
  }

  void _loadCurrent() {
    _videoController?.dispose();
    _videoController = null;

    if (_items.isEmpty) return;
    final item = _items[_currentIndex];

    if (item.type == ContentType.video) {
      if (kIsWeb) {
        if (item.webUrl == null) return;
        _videoController = VideoPlayerController.networkUrl(Uri.parse(item.webUrl!));
      } else {
        if (item.path.isEmpty) return;
        if (item.path.startsWith('assets/')) {
          _videoController = VideoPlayerController.asset(item.path);
        } else {
          _videoController = VideoPlayerController.file(File(item.path));
        }
      }
      _videoController!.initialize().then((_) {
        if (!mounted) return;
        final shouldLoop = _items.length == 1;
        _videoController!.setLooping(shouldLoop);
        _videoController!.play();
        if (!shouldLoop) _videoController!.addListener(_onVideoListener);
        setState(() {});
      });
    }
  }

  void _onVideoListener() {
    final ctrl = _videoController;
    if (ctrl == null) return;
    if (ctrl.value.position >= ctrl.value.duration - const Duration(milliseconds: 300)) {
      _next();
    }
  }

  void _next() {
    if (_items.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _items.length;
    _loadCurrent();
  }

  @override
  void dispose() {
    _videoController?.dispose();
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

    if (_videoController?.value.isInitialized == true) {
      return ClipRect(
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
        ),
      );
    }

    return Container(color: Colors.black);
  }
}
