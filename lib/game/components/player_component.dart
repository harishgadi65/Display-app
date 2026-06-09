import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../endless_runner_game.dart';

class PlayerComponent extends RectangleComponent
    with HasGameReference<EndlessRunnerGame> {
  static const double laneWidth = 120.0;
  static const int laneCount = 3;

  int _currentLane = 1;
  bool _isMoving = false;

  PlayerComponent()
      : super(
          size: Vector2(60, 80),
          paint: Paint()..color = const Color(0xFF00E5FF),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _updatePosition(animate: false);
  }

  double _laneX(int lane) {
    final gameWidth = game.size.x;
    final totalWidth = laneCount * laneWidth;
    final startX = (gameWidth - totalWidth) / 2;
    return startX + lane * laneWidth + (laneWidth - size.x) / 2;
  }

  void moveLeft() {
    if (_currentLane > 0 && !_isMoving) {
      _currentLane--;
      _updatePosition();
    }
  }

  void moveRight() {
    if (_currentLane < laneCount - 1 && !_isMoving) {
      _currentLane++;
      _updatePosition();
    }
  }

  void _updatePosition({bool animate = true}) {
    final targetX = _laneX(_currentLane);
    if (animate) {
      _isMoving = true;
      add(
        MoveToEffect(
          Vector2(targetX, y),
          EffectController(duration: 0.15),
          onComplete: () => _isMoving = false,
        ),
      );
    } else {
      x = targetX;
    }
  }

  int get currentLane => _currentLane;
}
