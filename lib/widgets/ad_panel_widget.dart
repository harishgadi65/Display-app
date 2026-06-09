import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/content_item.dart';
import '../services/content_service.dart';

class AdPanelWidget extends StatefulWidget {
  final int startOffset;

  const AdPanelWidget({super.key, this.startOffset = 0});

  @override
  State<AdPanelWidget> createState() => _AdPanelWidgetState();
}

class _AdPanelWidgetState extends State<AdPanelWidget> {
  final _service = ContentService();
  List<ContentItem> _items = [];
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  Timer? _imageTimer;

  @override
  void initState() {
    super.initState();
    _items = _service.selectedItems;
    if (_items.isNotEmpty) {
      _currentIndex = widget.startOffset % _items.length;
      _loadCurrent();
    }
  }

  void _loadCurrent() {
    _videoController?.dispose();
    _videoController = null;
    _imageTimer?.cancel();

    if (_items.isEmpty) return;
    final item = _items[_currentIndex];

    if (item.type == ContentType.video) {
      _videoController = VideoPlayerController.file(File(item.path));
      _videoController!.initialize().then((_) {
        if (!mounted) return;
        _videoController!.play();
        _videoController!.addListener(_onVideoListener);
        setState(() {});
      });
    } else {
      _imageTimer = Timer(const Duration(seconds: 5), _next);
      setState(() {});
    }
  }

  void _onVideoListener() {
    final ctrl = _videoController;
    if (ctrl == null) return;
    if (ctrl.value.position >= ctrl.value.duration - const Duration(milliseconds: 200)) {
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
    _imageTimer?.cancel();
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

    final item = _items[_currentIndex];
    if (item.type == ContentType.image) {
      return Image.file(File(item.path), fit: BoxFit.cover);
    }

    if (_videoController?.value.isInitialized == true) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    return Container(color: Colors.black);
  }
}
