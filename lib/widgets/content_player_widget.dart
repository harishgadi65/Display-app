import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/content_item.dart';

class ContentPlayerWidget extends StatefulWidget {
  final ContentItem item;
  final BoxFit fit;

  const ContentPlayerWidget({
    super.key,
    required this.item,
    this.fit = BoxFit.cover,
  });

  @override
  State<ContentPlayerWidget> createState() => _ContentPlayerWidgetState();
}

class _ContentPlayerWidgetState extends State<ContentPlayerWidget> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.item.type == ContentType.video) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.file(File(widget.item.path));
    await _controller!.initialize();
    _controller!.setLooping(true);
    _controller!.play();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item.type == ContentType.image) {
      return Image.file(
        File(widget.item.path),
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return _placeholder();
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF0A0A2E),
        child: const Center(
          child: Icon(Icons.play_circle_outline, color: Color(0xFF00E5FF), size: 48),
        ),
      );
}
