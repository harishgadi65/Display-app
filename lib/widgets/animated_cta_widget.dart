import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedCtaWidget extends StatelessWidget {
  const AnimatedCtaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PulsingDots(),
        const SizedBox(height: 12),
        Text(
          'SCAN QR CODE BELOW',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            letterSpacing: 4,
            fontWeight: FontWeight.w300,
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 1.seconds)
            .then()
            .fadeOut(duration: 1.seconds),
      ],
    );
  }
}

class _PulsingDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Color(0xFF00E5FF),
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .scaleXY(
              begin: 0.5,
              end: 1.5,
              duration: 800.ms,
              delay: (i * 200).ms,
              curve: Curves.easeInOut,
            )
            .then()
            .scaleXY(begin: 1.5, end: 0.5, duration: 800.ms),
      ),
    );
  }
}
