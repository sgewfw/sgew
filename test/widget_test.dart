// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:sgew/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FernwaermeApp());

    // Verify that the app renders something
    expect(find.text('SGEW'), findsOneWidget);
  });
}
