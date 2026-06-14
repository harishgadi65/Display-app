import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class CatchEffectComponent extends TextComponent {
  CatchEffectComponent({required int points, required Vector2 position})
      : super(
          text: '+$points',
          position: position,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: TextStyle(
              color: points >= 50
                  ? const Color(0xFFFFD700)
                  : points >= 15
                      ? const Color(0xFFFFA500)
                      : const Color(0xFF00CC44),
              fontSize: points >= 50 ? 22 : 16,
              fontWeight: FontWeight.w900,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black26)],
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(
      MoveByEffect(
        Vector2(0, -50),
        EffectController(duration: 0.8, curve: Curves.easeOut),
      ),
    );
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.8),
        onComplete: removeFromParent,
      ),
    );
  }
}
