import 'package:flutter_test/flutter_test.dart';
import 'package:blink_board/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BlinkBoardApp());
    expect(find.byType(BlinkBoardApp), findsOneWidget);
  });
}
