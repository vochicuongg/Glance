import 'package:flutter_test/flutter_test.dart';
import 'package:glance/main.dart';

void main() {
  testWidgets('GlanceApp renders dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const GlanceApp());

    // Verify the app title is displayed in the AppBar
    expect(find.text('GLANCE'), findsOneWidget);

    // Verify the main status text is displayed (default: inactive)
    expect(find.text('Protection Disabled'), findsOneWidget);
  });
}
