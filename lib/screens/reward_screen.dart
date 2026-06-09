import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/reward.dart';
import 'main_display_screen.dart';

class RewardScreen extends StatefulWidget {
  final int score;

  const RewardScreen({super.key, required this.score});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  late final Reward _reward;
  int _countdown = 15;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _reward = Reward.generate(widget.score);
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        _returnToMain();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _returnToMain() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainDisplayScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 800),
      ),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050516),
      body: Stack(
        children: [
          _ParticleBackground(),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTitle(),
                  const SizedBox(height: 24),
                  _buildScore(),
                  const SizedBox(height: 32),
                  _buildMessage(),
                  const SizedBox(height: 40),
                  _buildCoupon(),
                  const SizedBox(height: 40),
                  _buildCountdown(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          widget.score >= 100 ? '🎉 WINNER!' : 'GAME OVER',
          style: TextStyle(
            color: widget.score >= 100 ? const Color(0xFFFFD700) : const Color(0xFF00E5FF),
            fontSize: 52,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        )
            .animate()
            .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut)
            .fadeIn(duration: 400.ms),
      ],
    );
  }

  Widget _buildScore() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E5FF), width: 2),
        color: const Color(0xFF00E5FF).withOpacity(0.05),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'YOUR SCORE',
            style: TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 3),
          ),
          const SizedBox(height: 8),
          Text(
            widget.score.toString().padLeft(5, '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          )
              .animate()
              .slideY(begin: 1, duration: 500.ms, delay: 200.ms, curve: Curves.easeOut)
              .fadeIn(duration: 400.ms, delay: 200.ms),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 300.ms);
  }

  Widget _buildMessage() {
    return Text(
      _reward.message,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 20,
        fontWeight: FontWeight.w400,
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 500.ms)
        .slideY(begin: 0.5, duration: 500.ms, delay: 500.ms);
  }

  Widget _buildCoupon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A3A), Color(0xFF0A1A3A)],
        ),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.card_giftcard, color: Color(0xFFFFD700), size: 20),
              SizedBox(width: 8),
              Text(
                'YOUR REWARD CODE',
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 13, letterSpacing: 2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _reward.couponCode,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Show this code at the counter to claim your reward',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 700.ms)
        .shimmer(
          delay: 1200.ms,
          duration: 1500.ms,
          color: const Color(0xFFFFD700).withOpacity(0.2),
        );
  }

  Widget _buildCountdown() {
    return Column(
      children: [
        Text(
          'Returning to display in $_countdown seconds',
          style: const TextStyle(color: Colors.white38, fontSize: 14),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _returnToMain,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text(
              'Back to Display',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 1000.ms);
  }
}

class _ParticleBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(painter: _StarPainter()),
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF00E5FF).withOpacity(0.1);
    final positions = [
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.9, size.height * 0.15),
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.85, size.height * 0.75),
      Offset(size.width * 0.5, size.height * 0.05),
      Offset(size.width * 0.3, size.height * 0.5),
      Offset(size.width * 0.7, size.height * 0.4),
    ];
    for (final pos in positions) {
      canvas.drawCircle(pos, 2, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
