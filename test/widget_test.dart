
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_oreum/main.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const JejuOreumApp());

    // Verify that the login screen is shown.
    expect(find.text('카카오로 시작하기'), findsOneWidget);
    expect(find.text('로그인 없이 둘러보기'), findsOneWidget);
  });
}
