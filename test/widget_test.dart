import 'package:flutter_test/flutter_test.dart';
import 'package:basera/main.dart';

void main() {
  testWidgets('App loads Sign Up Screen successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BasseraApp());

    // Allow ScreenUtilInit and the layout engine to render
    await tester.pumpAndSettle();

    // Verify that the SignUpScreen is displayed by asserting key visual text blocks
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Choose Your Role'), findsOneWidget);
  });
}
