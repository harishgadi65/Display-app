import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QrOverlayWidget extends StatelessWidget {
  final String data;
  final VoidCallback? onStart;

  const QrOverlayWidget({super.key, required this.data, this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 82,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan to Play',
                  style: TextStyle(
                    color: const Color(0xFF00E5FF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.8),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                if (onStart != null)
                  GestureDetector(
                    onTap: onStart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Text(
                        '▶  Start',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  )
                else
                  const Text(
                    '& Win Rewards',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 3.seconds, color: const Color(0xFF00E5FF).withOpacity(0.2));
  }
}
