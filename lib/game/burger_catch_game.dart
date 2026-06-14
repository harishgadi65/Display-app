import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'components/falling_item_component.dart';
import 'components/tray_component.dart';

class BurgerCatchGame extends FlameGame with HasCollisionDetection {
  void Function(int score) onGameOver;
  void Function(int score) onScoreUpdate;
  void Function(double timeRemaining) onTimerTick;
  VoidCallback? onCountUpdate;

  int score = 0;
  int caughtCount = 0;
  double timeRemaining = 30.0;
  bool isRunning = false;

  double _spawnTimer = 0;
  double _spawnInterval = 0.8;
  double fallSpeed = 150.0;
  bool _preSpawnDone = false;

  late TrayComponent _tray;
  final Random _random = Random();

  BurgerCatchGame({
    required this.onGameOver,
    required this.onScoreUpdate,
    void Function(double)? onTimerTick,
  }) : onTimerTick = onTimerTick ?? ((_) {});

  @override
  Color backgroundColor() => Colors.white;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _tray = TrayComponent();
    add(_tray);
    overlays.add('hud');
    startGame();
  }

  void startGame() {
    score = 0;
    caughtCount = 0;
    timeRemaining = 30.0;
    _spawnTimer = 0;
    _spawnInterval = 0.8;
    fallSpeed = 150.0;
    _preSpawnDone = false;
    isRunning = true;

    children.whereType<FallingItemComponent>().toList().forEach((c) => c.removeFromParent());
    overlays.remove('gameOver');
    if (!overlays.isActive('hud')) overlays.add('hud');
    onScoreUpdate(0);
    onCountUpdate?.call();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isRunning) return;

    if (!_preSpawnDone) {
      _preSpawnDone = true;
      const margin = 30.0;
      for (int i = 0; i < 2; i++) {
        final x = margin + _random.nextDouble() * (size.x - margin * 2);
        add(FallingItemComponent(
          type: FallingItemComponent.randomType(),
          startX: x,
        ));
      }
    }

    final prevSec = timeRemaining.ceil();
    timeRemaining -= dt;
    if (timeRemaining <= 0) {
      timeRemaining = 0;
      _endGame();
      return;
    }
    if (timeRemaining.ceil() != prevSec) onTimerTick(timeRemaining);

    // Ramp difficulty
    final elapsed = 30.0 - timeRemaining;
    _spawnInterval = (0.8 - elapsed * 0.015).clamp(0.4, 0.8);
    fallSpeed = (150.0 + elapsed * 8).clamp(150.0, 400.0);

    // Spawn items
    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      _spawnItem();
    }
  }

  void _spawnItem() {
    final margin = 30.0;
    final x = margin + _random.nextDouble() * (size.x - margin * 2);
    add(FallingItemComponent(type: FallingItemComponent.randomType(), startX: x));
  }

  void addScore(int points) {
    score += points;
    caughtCount++;
    onScoreUpdate(score);
    onCountUpdate?.call();
  }

  void _endGame() {
    isRunning = false;
    overlays.remove('hud');
    overlays.add('gameOver');
    onGameOver(score);
  }

  void startMoveLeft() => _tray.startMoveLeft();
  void stopMoveLeft() => _tray.stopMoveLeft();
  void startMoveRight() => _tray.startMoveRight();
  void stopMoveRight() => _tray.stopMoveRight();
}
