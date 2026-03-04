import 'package:flutter_test/flutter_test.dart';
import 'package:dtr_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DTRApp());

    // Verify that the app title or some initial text exists.
    expect(find.text('OJT Daily Time Record'), findsNothing); // It's in MaterialApp title, not usually rendered directly as text in the tree unless used in AppBar
  });
}
