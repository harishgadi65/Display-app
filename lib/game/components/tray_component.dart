import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../burger_catch_game.dart';

class TrayComponent extends PositionComponent
    with HasGameReference<BurgerCatchGame> {
  static const double trayWidth = 110;
  static const double trayHeight = 18;
  static const double speed = 280;

  bool _movingLeft = false;
  bool _movingRight = false;

  TrayComponent() : super(size: Vector2(trayWidth, trayHeight), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(game.size.x / 2, game.size.y - 40);
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    // Tray body
    final bodyPaint = Paint()..color = const Color(0xFF8B4513);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 4, trayWidth, trayHeight - 4),
        const Radius.circular(6),
      ),
      bodyPaint,
    );
    // Tray rim highlight
    final rimPaint = Paint()..color = const Color(0xFFCD853F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, trayWidth, 6),
        const Radius.circular(4),
      ),
      rimPaint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isRunning) return;
    if (_movingLeft) x = (x - speed * dt).clamp(trayWidth / 2, game.size.x - trayWidth / 2);
    if (_movingRight) x = (x + speed * dt).clamp(trayWidth / 2, game.size.x - trayWidth / 2);
  }

  void startMoveLeft() => _movingLeft = true;
  void stopMoveLeft() => _movingLeft = false;
  void startMoveRight() => _movingRight = true;
  void stopMoveRight() => _movingRight = false;
}
