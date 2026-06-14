import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../burger_catch_game.dart';
import 'catch_effect_component.dart';
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
    with HasGameReference<BurgerCatchGame>, CollisionCallbacks {
  final FoodType type;
  static const double _itemSize = 56;
  bool _caught = false;
  Sprite? _sprite;

  FallingItemComponent({required this.type, required double startX, double? startY})
      : super(
          size: Vector2.all(_itemSize),
          anchor: Anchor.center,
        ) {
    x = startX;
    y = startY ?? -_itemSize;
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
    _sprite = await Sprite.load('burgar.png');
    add(CircleHitbox(radius: _itemSize / 2, anchor: Anchor.center));
  }

  @override
  void render(Canvas canvas) {
    _sprite?.render(canvas, size: size);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_caught) return;
    y += game.fallSpeed * dt;
    if (y > game.size.y + _itemSize / 2) removeFromParent();
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
