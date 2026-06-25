import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
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
  String _sessionCode = '';
  String? _deviceIp;
  List<ContentItem> _items = [];
  int _currentIndex = 0;

  Player? _bgPlayer;
  VideoController? _bgController;
  StreamSubscription? _bgPositionSub;

  Player? _contentPlayer;
  VideoController? _contentController;
  StreamSubscription? _contentCompletedSub;

  Timer? _contentTimer;
  StreamSubscription? _wsSub;
  int _cornerTapCount = 0;
  Timer? _cornerTapTimer;
  int? _countdownValue;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _contentService.load();
    final ip = await _wsServer.start();
    _deviceIp = ip;
    _sessionCode = (10000 + Random().nextInt(90000)).toString();
    setState(() {
      _qrData = 'http://${ip ?? "0.0.0.0"}:${_wsServer.port}?code=$_sessionCode';
      _items = _contentService.selectedItems;
    });
    _startContent();
    _listenWebSocket();
    try {
      await _initBackgroundVideo();
    } catch (_) {}
  }

  Future<void> _initBackgroundVideo() async {
    _bgPlayer = Player();
    _bgController = VideoController(_bgPlayer!);
    await _bgPlayer!.setVolume(0);
    _bgPositionSub = _bgPlayer!.stream.position.listen(_onBgVideoProgress);
    final media = kIsWeb
        ? Media('videos/background_video.mp4')
        : Media('asset:///assets/videos/background_video.mp4');
    await _bgPlayer!.open(media);
    await _bgPlayer!.setPlaylistMode(PlaylistMode.loop);
    await _bgPlayer!.play();
    if (mounted) setState(() {});
  }

  void _onBgVideoProgress(Duration position) {
    if (position >= const Duration(seconds: 8)) {
      _bgPlayer?.seek(Duration.zero);
    }
  }

  void _listenWebSocket() {
    _wsSub = _wsServer.messages.listen((msg) {
      if (msg.type == WsMessageType.startGame) {
        if (mounted) _enterGameMode();
      } else if (msg.type == WsMessageType.startBurgerGame) {
        if (mounted) _enterScreenTwo();
      }
    });
  }

  void _startContent() {
    if (_items.isEmpty) return;
    _currentIndex = 0;
    _loadCurrentContent();
  }

  Future<void> _loadCurrentContent() async {
    _contentCompletedSub?.cancel();
    _contentCompletedSub = null;
    await _contentPlayer?.dispose();
    _contentPlayer = null;
    _contentController = null;
    _contentTimer?.cancel();

    if (_items.isEmpty) return;
    final item = _items[_currentIndex];

    if (item.type == ContentType.video) {
      _contentPlayer = Player();
      _contentController = VideoController(_contentPlayer!);
      _contentCompletedSub = _contentPlayer!.stream.completed.listen((done) {
        if (done && mounted) _nextContent();
      });
      final media = kIsWeb
          ? Media(item.webUrl ?? '')
          : Media(item.path.startsWith('assets/')
              ? 'asset:///${item.path}'
              : item.path);
      await _contentPlayer!.open(media);
      await _contentPlayer!.play();
      if (mounted) setState(() {});
    } else {
      _contentTimer = Timer(const Duration(seconds: 6), _nextContent);
      if (mounted) setState(() {});
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
    setState(() => _countdownValue = 7);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), _onCountdownTick);
  }

  void _onCountdownTick(Timer t) {
    if (!mounted) { t.cancel(); return; }
    if (_countdownValue == null) { t.cancel(); return; }
    if (_countdownValue! <= 0) {
      t.cancel();
      _navigateToScreenTwo();
      return;
    }
    setState(() => _countdownValue = _countdownValue! - 1);
  }

  void _navigateToScreenTwo() {
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
    _bgPositionSub?.cancel();
    _bgPlayer?.dispose();
    _contentCompletedSub?.cancel();
    _contentPlayer?.dispose();
    _contentTimer?.cancel();
    _countdownTimer?.cancel();
    _wsSub?.cancel();
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
          _buildCountdownOverlay(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    if (_bgController != null) {
      return SizedBox.expand(
        child: Video(
          controller: _bgController!,
          fit: BoxFit.cover,
          fill: Colors.black,
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

    if (_contentController != null) {
      return Center(
        child: Video(controller: _contentController!),
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
            onStart: _enterScreenTwo,
            sessionCode: _sessionCode,
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    if (_countdownValue == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Text(
              '$_countdownValue',
              key: ValueKey(_countdownValue),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 120,
                fontWeight: FontWeight.w900,
              ),
            ),
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
