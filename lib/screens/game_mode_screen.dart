import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../game/endless_runner_game.dart';
import '../services/websocket_server.dart';
import '../widgets/ad_panel_widget.dart';
import 'reward_screen.dart';

class GameModeScreen extends StatefulWidget {
  const GameModeScreen({super.key});

  @override
  State<GameModeScreen> createState() => _GameModeScreenState();
}

class _GameModeScreenState extends State<GameModeScreen> {
  final _wsServer = WebSocketServer();
  late EndlessRunnerGame _game;
  StreamSubscription? _wsSub;
  int _score = 0;
  bool _gameStarted = false;

  @override
  void initState() {
    super.initState();
    _game = EndlessRunnerGame(
      onGameOver: _handleGameOver,
      onScoreUpdate: (s) {
        if (mounted) setState(() => _score = s);
        _wsServer.sendScoreUpdate(s);
      },
    );
    _listenControls();
    _autoStart();
  }

  void _autoStart() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _gameStarted = true);
        _game.startGame();
      }
    });
  }

  void _listenControls() {
    _wsSub = _wsServer.messages.listen((msg) {
      switch (msg.type) {
        case WsMessageType.moveLeft:
          _game.moveLeft();
          break;
        case WsMessageType.moveRight:
          _game.moveRight();
          break;
        default:
          break;
      }
    });
  }

  void _handleGameOver(int score) {
    _wsServer.sendGameOver(score);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => RewardScreen(score: score),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          _buildTopBanner(),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ClipRect(child: AdPanelWidget(startOffset: 0)),
                ),
                Expanded(
                  flex: 4,
                  child: _buildGameArea(),
                ),
                Expanded(
                  flex: 2,
                  child: ClipRect(child: AdPanelWidget(startOffset: 1)),
                ),
              ],
            ),
          ),
          _buildBottomBanner(),
        ],
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D0D2B), Color(0xFF1A0A3A), Color(0xFF0D0D2B)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'BLINK BOARD',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(width: 40),
          const Text('SCORE', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(width: 10),
          Text(
            _score.toString().padLeft(5, '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(
          vertical: BorderSide(
            color: const Color(0xFF00E5FF).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          GameWidget(game: _game),
          if (!_gameStarted)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Text(
                  'GET READY!',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ),
            )
                .animate()
                .fadeOut(delay: 400.ms, duration: 600.ms),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.smartphone, color: Colors.white38, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Control via your phone',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBanner() {
    return Container(
      height: 40,
      color: const Color(0xFF050510),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF00FF88),
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 600.ms)
                .then()
                .fadeOut(duration: 600.ms),
            const SizedBox(width: 8),
            const Text(
              'GAME IN PROGRESS  •  Use arrow buttons on your phone to play',
              style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }
}
