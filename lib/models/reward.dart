class Reward {
  final int score;
  final String couponCode;
  final String message;
  final DateTime earnedAt;

  Reward({
    required this.score,
    required this.couponCode,
    required this.message,
    required this.earnedAt,
  });

  static Reward generate(int score) {
    final code = 'BLINK-${score.toString().padLeft(4, '0')}-${DateTime.now().millisecond}';
    String message;
    if (score >= 200) {
      message = 'Amazing! You\'re a Blink Champion!';
    } else if (score >= 100) {
      message = 'Great run! Keep it up!';
    } else {
      message = 'Nice try! Play again to win bigger rewards!';
    }
    return Reward(
      score: score,
      couponCode: code,
      message: message,
      earnedAt: DateTime.now(),
    );
  }
}
