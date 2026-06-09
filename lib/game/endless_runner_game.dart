import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'components/player_component.dart';
import 'components/obstacle_component.dart';

class EndlessRunnerGame extends FlameGame with HasCollisionDetection {
  late PlayerComponent _player;
  int score = 0;
  bool isRunning = false;

  final void Function(int score) onGameOver;
  final void Function(int score) onScoreUpdate;

  double _obstacleTimer = 0;
  double _obstacleInterval = 2.0;
  double _speed = 200.0;
  double _scoreTimer = 0;

  EndlessRunnerGame({
    required this.onGameOver,
    required this.onScoreUpdate,
  });

  @override
  Color backgroundColor() => const Color(0xFF0A0A1A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _player = PlayerComponent();
    _player.y = size.y - 150;
    add(_player);

    _drawLanes();
    _addPlayerHitbox();
  }

  void _drawLanes() {
    const laneWidth = 120.0;
    const laneCount = 3;
    final startX = (size.x - laneCount * laneWidth) / 2;

    for (int i = 1; i < laneCount; i++) {
      add(
        RectangleComponent(
          position: Vector2(startX + i * laneWidth, 0),
          size: Vector2(1, size.y),
          paint: Paint()..color = const Color(0xFF222244),
        ),
      );
    }

    add(
      RectangleComponent(
        position: Vector2(startX, size.y - 100),
        size: Vector2(laneCount * laneWidth, 2),
        paint: Paint()..color = const Color(0xFF00E5FF),
      ),
    );
  }

  void _addPlayerHitbox() {
    _player.add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isRunning) return;

    _obstacleTimer += dt;
    _scoreTimer += dt;

    if (_scoreTimer >= 0.1) {
      score++;
      _scoreTimer = 0;
      onScoreUpdate(score);
    }

    if (_obstacleTimer >= _obstacleInterval) {
      _spawnObstacle();
      _obstacleTimer = 0;
      _obstacleInterval = (_obstacleInterval - 0.05).clamp(0.6, 2.0);
      _speed = (_speed + 5).clamp(200, 500);
    }

    for (final obs in children.whereType<ObstacleComponent>().toList()) {
      obs.y += _speed * dt;

      if (_checkCollision(obs)) {
        _endGame();
        return;
      }

      if (obs.y > size.y + 50) {
        obs.removeFromParent();
      }
    }
  }

  bool _checkCollision(ObstacleComponent obs) {
    if (obs.lane != _player.currentLane) return false;
    final playerTop = _player.y;
    final playerBottom = _player.y + _player.height;
    final obsTop = obs.y;
    final obsBottom = obs.y + obs.height;
    return playerBottom > obsTop && playerTop < obsBottom;
  }

  void _spawnObstacle() {
    final obs = ObstacleComponent(lane: ObstacleComponent.randomLane());
    add(obs);
  }

  void startGame() {
    score = 0;
    isRunning = true;
    _obstacleInterval = 2.0;
    _speed = 200.0;
    _obstacleTimer = 0;
    _scoreTimer = 0;
    children.whereType<ObstacleComponent>().toList().forEach((o) => o.removeFromParent());
  }

  void moveLeft() => _player.moveLeft();
  void moveRight() => _player.moveRight();

  void _endGame() {
    isRunning = false;
    children.whereType<ObstacleComponent>().toList().forEach((o) => o.removeFromParent());
    onGameOver(score);
  }
}
