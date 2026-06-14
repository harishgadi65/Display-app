import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/content_item.dart';
import '../services/content_service.dart';
import '../services/websocket_server.dart';
import '../widgets/qr_overlay_widget.dart';
import 'game_mode_screen.dart';
import 'screen_two.dart';
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
  VideoPlayerController? _bgVideoController;
  Timer? _contentTimer;
  Timer? _screenTimer;
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
    await _initBackgroundVideo();
    _screenTimer = Timer(const Duration(seconds: 15), _enterScreenTwo);
  }

  Future<void> _initBackgroundVideo() async {
    _bgVideoController = kIsWeb
        ? VideoPlayerController.networkUrl(
            Uri.parse('videos/background_video.mp4'),
          )
        : VideoPlayerController.asset('assets/videos/Background video.mp4');
    await _bgVideoController!.initialize();
    await _bgVideoController!.setVolume(0);
    _bgVideoController!.addListener(_onBgVideoProgress);
    await _bgVideoController!.play();
    if (mounted) setState(() {});
  }

  void _onBgVideoProgress() {
    final ctrl = _bgVideoController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (ctrl.value.position >= const Duration(seconds: 8)) {
      ctrl.seekTo(Duration.zero);
    }
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

  void _enterScreenTwo() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ScreenTwo(),
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
    _bgVideoController?.dispose();
    _videoController?.dispose();
    _contentTimer?.cancel();
    _screenTimer?.cancel();
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
    if (_bgVideoController?.value.isInitialized == true) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _bgVideoController!.value.size.width,
            height: _bgVideoController!.value.size.height,
            child: VideoPlayer(_bgVideoController!),
          ),
        ),
      );
    }
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
    if (_items.isEmpty) return const SizedBox.shrink();

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
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: QrOverlayWidget(
            data: _qrData.isEmpty ? 'https://blinkboard.app' : _qrData,
          ),
        ),
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
