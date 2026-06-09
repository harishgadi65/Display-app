import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/content_item.dart';
import '../services/content_service.dart';
import '../services/websocket_server.dart';
import '../widgets/qr_overlay_widget.dart';
import '../widgets/animated_cta_widget.dart';
import 'game_mode_screen.dart';
import 'demo_setup/demo_setup_screen.dart';

class MainDisplayScreen extends StatefulWidget {
  const MainDisplayScreen({super.key});

  @override
  State<MainDisplayScreen> createState() => _MainDisplayScreenState();
}

class _MainDisplayScreenState extends State<MainDisplayScreen> {
  final _contentService = ContentService();
  final _wsServer = WebSocketServer();

  String _qrData = '';
  String? _deviceIp;
  List<ContentItem> _items = [];
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  Timer? _contentTimer;
  StreamSubscription? _wsSub;
  int _cornerTapCount = 0;
  Timer? _cornerTapTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _contentService.load();
    final ip = await _wsServer.start();
    _deviceIp = ip;
    setState(() {
      _qrData = 'http://${ip ?? "0.0.0.0"}:${_wsServer.port}';
      _items = _contentService.selectedItems;
    });
    _startContent();
    _listenWebSocket();
  }

  void _listenWebSocket() {
    _wsSub = _wsServer.messages.listen((msg) {
      if (msg.type == WsMessageType.startGame) {
        if (mounted) _enterGameMode();
      }
    });
  }

  void _startContent() {
    if (_items.isEmpty) return;
    _currentIndex = 0;
    _loadCurrentContent();
  }

  void _loadCurrentContent() {
    _videoController?.dispose();
    _videoController = null;
    _contentTimer?.cancel();

    if (_items.isEmpty) return;
    final item = _items[_currentIndex];

    if (item.type == ContentType.video) {
      _videoController = VideoPlayerController.file(File(item.path));
      _videoController!.initialize().then((_) {
        if (!mounted) return;
        _videoController!.play();
        _videoController!.addListener(_onVideoProgress);
        setState(() {});
      });
    } else {
      _contentTimer = Timer(const Duration(seconds: 6), _nextContent);
      setState(() {});
    }
  }

  void _onVideoProgress() {
    final ctrl = _videoController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (ctrl.value.position >= ctrl.value.duration - const Duration(milliseconds: 300)) {
      _nextContent();
    }
  }

  void _nextContent() {
    if (_items.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _items.length;
    _loadCurrentContent();
  }

  void _enterGameMode() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GameModeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _onCornerTap() {
    _cornerTapTimer?.cancel();
    _cornerTapCount++;
    if (_cornerTapCount >= 5) {
      _cornerTapCount = 0;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DemoSetupScreen()),
      ).then((_) {
        _init();
      });
      return;
    }
    _cornerTapTimer = Timer(const Duration(seconds: 3), () => _cornerTapCount = 0);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _contentTimer?.cancel();
    _wsSub?.cancel();
    _wsServer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackground(),
          _buildContent(),
          _buildOverlay(),
          _buildCornerTapTarget(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF050516), Color(0xFF0A0A2E), Color(0xFF050516)],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_outline, color: Color(0xFF00E5FF), size: 80),
            const SizedBox(height: 16),
            const Text(
              'BLINK BOARD',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.4)),
            const SizedBox(height: 8),
            const Text(
              'Add content via Demo Setup (tap corner 5×)',
              style: TextStyle(color: Colors.white38, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final item = _items[_currentIndex];
    if (item.type == ContentType.image) {
      return SizedBox.expand(
        child: Image.file(File(item.path), fit: BoxFit.cover),
      );
    }

    if (_videoController?.value.isInitialized == true) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildOverlay() {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBrand(),
          const Spacer(),
          const AnimatedCtaWidget(),
          const SizedBox(height: 16),
          QrOverlayWidget(data: _qrData.isEmpty ? 'https://blinkboard.app' : _qrData),
          if (_deviceIp != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 16),
              child: Text(
                'Connected on $_deviceIp',
                style: const TextStyle(color: Colors.white24, fontSize: 11),
              ),
            )
          else
            const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTopBrand() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            'BLINK',
            style: TextStyle(
              color: const Color(0xFF00E5FF),
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              shadows: [
                Shadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.6),
                  blurRadius: 16,
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 3.seconds, color: Colors.white.withOpacity(0.3)),
          const Text(
            ' BOARD',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w300,
              letterSpacing: 4,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00FF88),
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(duration: 800.ms)
                    .then()
                    .fadeOut(duration: 800.ms),
                const SizedBox(width: 6),
                const Text('LIVE', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerTapTarget() {
    return Positioned(
      top: 0,
      right: 0,
      child: GestureDetector(
        onTap: _onCornerTap,
        child: Container(
          width: 60,
          height: 60,
          color: Colors.transparent,
        ),
      ),
    );
  }
}
