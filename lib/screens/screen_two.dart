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
                        child: Container(
                          color: Colors.white,
                          child: GameWidget(
                            game: _game,
                            overlayBuilderMap: {
                              'hud': (ctx, game) => _HudOverlay(
                                    game: game as BurgerCatchGame,
                                    onLeft: () => _game.startMoveLeft(),
                                    onLeftUp: () => _game.stopMoveLeft(),
                                    onRight: () => _game.startMoveRight(),
                                    onRightUp: () => _game.stopMoveRight(),
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

// ── HUD overlay ──────────────────────────────────────────────────────────────

class _HudOverlay extends StatefulWidget {
  final BurgerCatchGame game;
  final VoidCallback onLeft;
  final VoidCallback onLeftUp;
  final VoidCallback onRight;
  final VoidCallback onRightUp;

  const _HudOverlay({
    required this.game,
    required this.onLeft,
    required this.onLeftUp,
    required this.onRight,
    required this.onRightUp,
  });

  @override
  State<_HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<_HudOverlay> {
  @override
  void initState() {
    super.initState();
    widget.game.onScoreUpdate = (_) => setState(() {});
    widget.game.onTimerTick = (_) => setState(() {});
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
              '🍔 ${widget.game.score}',
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

        // Control buttons
        Positioned(
          bottom: 6,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTapDown: (_) => widget.onLeft(),
                onTapUp: (_) => widget.onLeftUp(),
                onTapCancel: widget.onLeftUp,
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
                  child: const Center(child: Text('<', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTapDown: (_) => widget.onRight(),
                onTapUp: (_) => widget.onRightUp(),
                onTapCancel: widget.onRightUp,
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
                  child: const Center(child: Text('>', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                ),
              ),
            ],
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
      color: Colors.black.withOpacity(0.82),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 6),
            const Text(
              'Congratulations!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${game.score}',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 52,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'POINTS',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 16),

            // Coupon placeholder
            Container(
              width: 180,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white38, width: 1.5),
              ),
              child: const Column(
                children: [
                  Text('🎫 YOUR REWARD',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.5)),
                  SizedBox(height: 4),
                  Text('Scan QR to claim',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Play Again
            GestureDetector(
              onTap: onPlayAgain,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  '▶  Play Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
