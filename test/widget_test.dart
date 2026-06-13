import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/main.dart';

void main() {
  testWidgets('GlanceApp renders with provided home', (WidgetTester tester) async {
    // GlanceApp now requires a `home` widget (pre-resolved in main()).
    // For testing, we provide a simple Scaffold as the home screen.
    await tester.pumpWidget(
      const GlanceApp(
        home: Scaffold(body: Center(child: Text('Test Home'))),
      ),
    );

    expect(find.text('Test Home'), findsOneWidget);
  });
}
