import 'package:flutter_test/flutter_test.dart';
import 'package:tpm_ta/main.dart';
import 'package:tpm_ta/screens/login_screen.dart';

void main() {
  testWidgets('App starts and renders LoginScreen by default', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(initialSessionToken: null));

    // Verify that the LoginScreen is rendered.
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('T-Shirt Studio'), findsOneWidget);
  });
}
