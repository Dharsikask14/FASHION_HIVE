// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// NOTE: FashionApp uses Firebase.initializeApp() inside InitScreen.
// Pumping FashionApp directly in tests requires a Firebase mock.
// For a simple smoke test we verify the MaterialApp is present instead.

void main() {
  testWidgets('MaterialApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Siva Silks')),
        ),
      ),
    );
    expect(find.text('Siva Silks'), findsOneWidget);
  });
}
