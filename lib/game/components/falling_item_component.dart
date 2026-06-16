import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../burger_catch_game.dart';
import 'tray_component.dart';

enum FoodType {
  patty(points: 10, emoji: '🍔'),
  cheese(points: 15, emoji: '🧀'),
  lettuce(points: 5, emoji: '🥬'),
  goldenPatty(points: 50, emoji: '⭐');

  const FoodType({required this.points, required this.emoji});
  final int points;
  final String emoji;
}

class FallingItemComponent extends PositionComponent
    with HasGameReference<BurgerCatchGame> {
  final FoodType type;
  static const double _itemSize = 56;
  bool _caught = false;
  late final Sprite _sprite;

  bool get isCaught => _caught;

  FallingItemComponent({required this.type, required double startX, required Sprite sprite, double? startY})
      : super(
          size: Vector2.all(_itemSize),
          anchor: Anchor.center,
        ) {
    _sprite = sprite;
    x = startX;
    y = startY ?? _itemSize / 2;
  }

  static FoodType randomType() {
    final r = Random().nextDouble();
    if (r < 0.05) return FoodType.goldenPatty;
    if (r < 0.25) return FoodType.cheese;
    if (r < 0.50) return FoodType.lettuce;
    return FoodType.patty;
  }

  @override
  void render(Canvas canvas) {
    if (_caught) return;
    _sprite.render(canvas, size: size);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_caught) return;
    y += game.fallSpeed * dt;
  }

  bool overlapsWithTray(TrayComponent tray) {
    final burgerBottom = y + size.y / 2;
    final trayTop    = tray.y - tray.size.y / 2;
    final trayBottom = tray.y + tray.size.y / 2;
    final trayLeft   = tray.x - tray.size.x / 2;
    final trayRight  = tray.x + tray.size.x / 2;
    return burgerBottom >= trayTop &&
           y - size.y / 2 <= trayBottom &&
           x + size.x / 2 > trayLeft &&
           x - size.x / 2 < trayRight;
  }

  void markCaught() {
    _caught = true;
    removeFromParent();
  }
}
