import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../burger_catch_game.dart';

class TrayComponent extends PositionComponent
    with HasGameReference<BurgerCatchGame> {
  static const double trayWidth = 65;
  static const double trayHeight = 43;
  static const double speed = 280;

  bool _movingLeft = false;
  bool _movingRight = false;
  Sprite? _sprite;

  TrayComponent() : super(size: Vector2(trayWidth, trayHeight), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(game.size.x / 2, game.size.y - 50);
    _sprite = await Sprite.load('basket.png');
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    _sprite?.render(canvas, size: size);
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
