import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/burger_catch_game.dart';
import '../models/content_item.dart';
import '../services/panel_video_service.dart';
import '../widgets/panel_video_player.dart';
import '../widgets/top_bar_video_player.dart';
import 'main_display_screen.dart';

class ScreenTwo extends StatefulWidget {
  const ScreenTwo({super.key});

  @override
  State<ScreenTwo> createState() => _ScreenTwoState();
}

class _ScreenTwoState extends State<ScreenTwo> {
  late BurgerCatchGame _game;

  bool _preGameCountdown = false;
  int _preGameCount = 3;
  Timer? _preGameTimer;

  @override
  void initState() {
    super.initState();
    _game = BurgerCatchGame(
      onGameOver: (_) {},
      onScoreUpdate: (_) {},
    );
  }

  @override
  void dispose() {
    _preGameTimer?.cancel();
    super.dispose();
  }

  void _restartGame() {
    setState(() {
      _preGameCountdown = true;
      _preGameCount = 3;
    });
    _preGameTimer?.cancel();
    _preGameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) { _preGameTimer?.cancel(); return; }
      setState(() => _preGameCount--);
      if (_preGameCount <= 0) {
        _preGameTimer?.cancel();
        setState(() => _preGameCountdown = false);
        _game.startGame();
      }
    });
  }

  void _returnToScreenOne() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainDisplayScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final adH = h * 0.15;
          final adW = w * 0.15;

          return Column(
            children: [
              SizedBox(
                height: adH,
                width: double.infinity,
                child: const TopBarVideoPlayer(),
              ),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: adW,
                      child: PanelVideoPlayer(
                        service: PanelVideoService('screen2_left', defaultItem: ContentItem(
                          id: 'left_1',
                          path: r'D:\Claude Projects\left side.mp4',
                          type: ContentType.video,
                          name: 'left side.mp4',
                          webUrl: 'videos/left_side.mp4',
                        )),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.black,
                        padding: const EdgeInsets.all(3),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                color: Colors.white,
                                child: GameWidget(
                                  game: _game,
                                  overlayBuilderMap: {
                                    'hud': (ctx, game) => _HudOverlay(
                                          game: game as BurgerCatchGame,
                                        ),
                                    'gameOver': (ctx, game) => _GameOverOverlay(
                                          game: game as BurgerCatchGame,
                                          onPlayAgain: _restartGame,
                                          onExit: _returnToScreenOne,
                                        ),
                                  },
                                  initialActiveOverlays: const ['hud'],
                                ),
                              ),
                            ),
                            // Nav buttons outside GameWidget for reliable web pointer events
                            Positioned(
                              bottom: 6,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _NavButton(
                                    label: '<',
                                    onPress: () => _game.startMoveLeft(),
                                    onRelease: () => _game.stopMoveLeft(),
                                  ),
                                  const SizedBox(width: 24),
                                  _NavButton(
                                    label: '>',
                                    onPress: () => _game.startMoveRight(),
                                    onRelease: () => _game.stopMoveRight(),
                                  ),
                                ],
                              ),
                            ),
                            // 3-2-1 pre-game countdown overlay
                            if (_preGameCountdown)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withOpacity(0.75),
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 250),
                                      transitionBuilder: (child, anim) => ScaleTransition(
                                        scale: anim,
                                        child: FadeTransition(opacity: anim, child: child),
                                      ),
                                      child: Text(
                                        _preGameCount > 0 ? '$_preGameCount' : 'GO!',
                                        key: ValueKey(_preGameCount),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 96,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: adW,
                      child: PanelVideoPlayer(
                        service: PanelVideoService('screen2_right', defaultItem: ContentItem(
                          id: 'right_1',
                          path: r'D:\Claude Projects\right side.mp4',
                          type: ContentType.video,
                          name: 'right side.mp4',
                          webUrl: 'videos/right_side.mp4',
                        )),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: adH,
                width: double.infinity,
                child: PanelVideoPlayer(
                  service: PanelVideoService('screen2_bottom', defaultItem: ContentItem(
                    id: 'bottom_1',
                    path: r'D:\Claude Projects\Botom.mp4',
                    type: ContentType.video,
                    name: 'Botom.mp4',
                    webUrl: 'videos/bottom.mp4',
                  )),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Nav button ────────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback onPress;
  final VoidCallback onRelease;

  const _NavButton({
    required this.label,
    required this.onPress,
    required this.onRelease,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onPress(),
      onPointerUp: (_) => onRelease(),
      onPointerCancel: (_) => onRelease(),
      child: Container(
        width: 52,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.orange.shade700,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ── HUD overlay (score + timer) ───────────────────────────────────────────────

class _HudOverlay extends StatefulWidget {
  final BurgerCatchGame game;

  const _HudOverlay({required this.game});

  @override
  State<_HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<_HudOverlay> {
  @override
  void initState() {
    super.initState();
    widget.game.onScoreUpdate = (_) { if (mounted) setState(() {}); };
    widget.game.onTimerTick = (_) { if (mounted) setState(() {}); };
    widget.game.onCountUpdate = () { if (mounted) setState(() {}); };
  }

  @override
  void dispose() {
    widget.game.onScoreUpdate = (_) {};
    widget.game.onTimerTick = (_) {};
    widget.game.onCountUpdate = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secs = widget.game.timeRemaining.ceil();
    final isLow = secs <= 10;

    return Stack(
      children: [
        Positioned(
          top: 8,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '🍔 x${widget.game.caughtCount}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isLow ? Colors.red.shade700 : Colors.green.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '⏱ $secs',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Game Over overlay (with 10-second auto-return countdown) ─────────────────

class _GameOverOverlay extends StatefulWidget {
  final BurgerCatchGame game;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const _GameOverOverlay({
    required this.game,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  State<_GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<_GameOverOverlay> {
  int _countdown = 10;
  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown <= 0) _autoExit();
    });
  }

  void _autoExit() {
    if (_navigated) return;
    _navigated = true;
    _timer?.cancel();
    widget.onExit();
  }

  void _onPlayAgain() {
    if (_navigated) return;
    _navigated = true;
    _timer?.cancel();
    widget.onPlayAgain();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.88),
      child: Center(
        child: Container(
          width: 220,
          padding: const EdgeInsets.fromLTRB(20, 1, 20, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.shade700, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🍔', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 4),
              const Text(
                'GAME OVER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              const Divider(color: Colors.orange, thickness: 1),
              const SizedBox(height: 12),

              // Burgers caught
              const Text(
                'Burgers Caught',
                style: TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 1),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.game.caughtCount}',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),

              // Total score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Score',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                    Text('${widget.game.score}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Auto-return countdown number
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Text(
                  '$_countdown',
                  key: ValueKey(_countdown),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Play Again button
              GestureDetector(
                onTap: _onPlayAgain,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text(
                      '▶  Play Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
