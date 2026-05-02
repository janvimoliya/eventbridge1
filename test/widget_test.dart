import 'package:flutter_test/flutter_test.dart';
import 'package:eventbridge1/screens/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Splash screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
