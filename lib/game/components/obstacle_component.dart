import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../endless_runner_game.dart';

class ObstacleComponent extends RectangleComponent
    with HasGameReference<EndlessRunnerGame> {
  static const double laneWidth = 120.0;
  static const int laneCount = 3;
  final int lane;

  ObstacleComponent({required this.lane})
      : super(
          size: Vector2(60, 60),
          paint: Paint()..color = const Color(0xFFFF1744),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final gameWidth = game.size.x;
    final totalWidth = laneCount * laneWidth;
    final startX = (gameWidth - totalWidth) / 2;
    x = startX + lane * laneWidth + (laneWidth - size.x) / 2;
    y = -size.y;
  }

  static int randomLane() => Random().nextInt(laneCount);
}
