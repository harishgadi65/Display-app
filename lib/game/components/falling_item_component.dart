import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../burger_catch_game.dart';
import 'catch_effect_component.dart';
import 'tray_component.dart';

enum FoodType {
  patty(points: 10, emoji: '🍔', color: Color(0xFF8B4513)),
  cheese(points: 15, emoji: '🧀', color: Color(0xFFFFD700)),
  lettuce(points: 5, emoji: '🥬', color: Color(0xFF4CAF50)),
  goldenPatty(points: 50, emoji: '⭐', color: Color(0xFFFFAB00));

  const FoodType({required this.points, required this.emoji, required this.color});
  final int points;
  final String emoji;
  final Color color;
}

class FallingItemComponent extends PositionComponent
    with HasGameReference<BurgerCatchGame>, CollisionCallbacks {
  final FoodType type;
  static const double _itemSize = 36;
  bool _caught = false;

  FallingItemComponent({required this.type, required double startX})
      : super(
          size: Vector2.all(_itemSize),
          anchor: Anchor.center,
        ) {
    x = startX;
    y = -_itemSize;
  }

  static FoodType randomType() {
    final r = Random().nextDouble();
    if (r < 0.05) return FoodType.goldenPatty;
    if (r < 0.25) return FoodType.cheese;
    if (r < 0.50) return FoodType.lettuce;
    return FoodType.patty;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: _itemSize / 2, anchor: Anchor.center));
  }

  @override
  void render(Canvas canvas) {
    // Glow circle
    final glowPaint = Paint()
      ..color = type.color.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(_itemSize / 2, _itemSize / 2), _itemSize / 2 + 4, glowPaint);

    // Filled circle
    final fillPaint = Paint()..color = type.color;
    canvas.drawCircle(Offset(_itemSize / 2, _itemSize / 2), _itemSize / 2, fillPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(_itemSize / 2, _itemSize / 2), _itemSize / 2, borderPaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_caught) return;
    y += game.fallSpeed * dt;
    if (y > game.size.y + _itemSize) removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (_caught || other is! TrayComponent) return;
    _caught = true;
    game.addScore(type.points);
    game.add(CatchEffectComponent(points: type.points, position: position.clone()));
    removeFromParent();
  }
}
