import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'components/catch_effect_component.dart';
import 'components/falling_item_component.dart';
import 'components/tray_component.dart';

class BurgerCatchGame extends FlameGame {
  void Function(int score) onGameOver;
  void Function(int score) onScoreUpdate;
  void Function(double timeRemaining) onTimerTick;
  VoidCallback? onCountUpdate;

  int score = 0;
  int caughtCount = 0;
  double timeRemaining = 30.0;
  bool isRunning = false;

  double fallSpeed = 150.0;
  bool _waitingForBurger = false;
  late Sprite _burgerSprite;

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
    _burgerSprite = await Sprite.load('burgar.png');
    _tray = TrayComponent();
    await add(_tray);
    overlays.add('hud');
    startGame();
  }

  void startGame() {
    score = 0;
    caughtCount = 0;
    timeRemaining = 30.0;
    fallSpeed = 150.0;
    _waitingForBurger = false;
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

    final prevSec = timeRemaining.ceil();
    timeRemaining -= dt;
    if (timeRemaining <= 0) {
      timeRemaining = 0;
      _endGame();
      return;
    }
    if (timeRemaining.ceil() != prevSec) onTimerTick(timeRemaining);

    final elapsed = 30.0 - timeRemaining;
    fallSpeed = (75.0 + elapsed * 3).clamp(75.0, 200.0);

    // Detect bottom-edge miss and tray catch
    for (final burger in children.whereType<FallingItemComponent>().toList()) {
      if (burger.isCaught) continue;

      if (burger.y + burger.size.y / 2 >= size.y) {
        burger.removeFromParent();
        continue;
      }

      if (burger.overlapsWithTray(_tray)) {
        burger.markCaught();
        addScore(burger.type.points);
        add(CatchEffectComponent(points: burger.type.points, position: burger.position.clone()));
      }
    }

    // Spawn next burger if none is active and we haven't already queued one
    final hasBurger = children
        .whereType<FallingItemComponent>()
        .any((b) => !b.isCaught);
    if (!hasBurger && !_waitingForBurger) {
      _waitingForBurger = true;
      _spawnNext();
    } else if (hasBurger) {
      _waitingForBurger = false;
    }
  }

  void _spawnNext() {
    if (!isRunning) return;
    const margin = 30.0;
    final x = margin + _random.nextDouble() * (size.x - margin * 2);
    add(FallingItemComponent(
      type: FallingItemComponent.randomType(),
      startX: x,
      sprite: _burgerSprite,
    ));
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
