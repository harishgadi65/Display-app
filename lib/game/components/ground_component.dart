import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../endless_runner_game.dart';

class LaneLineComponent extends PositionComponent
    with HasGameReference<EndlessRunnerGame> {
  LaneLineComponent({required super.position});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(2, game.size.y);
    add(
      RectangleComponent(
        size: size,
        paint: Paint()
          ..color = const Color(0xFF333333)
          ..style = PaintingStyle.fill,
      ),
    );
  }
}
