import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/burger_catch_game.dart';
import '../widgets/ad_panel_widget.dart';
import 'main_display_screen.dart';

class ScreenTwo extends StatefulWidget {
  const ScreenTwo({super.key});

  @override
  State<ScreenTwo> createState() => _ScreenTwoState();
}

class _ScreenTwoState extends State<ScreenTwo> {
  late BurgerCatchGame _game;

  @override
  void initState() {
    super.initState();
    _game = BurgerCatchGame(
      onGameOver: (_) {},
      onScoreUpdate: (_) {},
    );
  }

  void _restartGame() => _game.startGame();

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
                child: const AdPanelWidget(startOffset: 0),
              ),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: adW,
                      child: const AdPanelWidget(startOffset: 1),
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
                            // Buttons live outside GameWidget — reliable pointer events on web
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
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: adW,
                      child: const AdPanelWidget(startOffset: 2),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: adH,
                width: double.infinity,
                child: const AdPanelWidget(startOffset: 3),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Nav button (outside GameWidget for reliable web pointer events) ───────────

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

// ── HUD overlay (score + timer only) ─────────────────────────────────────────

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
        // Score
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

        // Timer
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

// ── Game Over overlay ─────────────────────────────────────────────────────────

class _GameOverOverlay extends StatelessWidget {
  final BurgerCatchGame game;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const _GameOverOverlay({
    required this.game,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.88),
      child: Center(
        child: Container(
          width: 220,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
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
              const SizedBox(height: 16),
              const Divider(color: Colors.orange, thickness: 1),
              const SizedBox(height: 12),

              // Burgers caught — primary stat
              const Text(
                'Burgers Caught',
                style: TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 1),
              ),
              const SizedBox(height: 4),
              Text(
                '${game.caughtCount}',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 12),

              // Total score — secondary stat
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
                    Text('${game.score}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Play Again
              GestureDetector(
                onTap: onPlayAgain,
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
