import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventbridge1/main.dart';

void main() {
  testWidgets('App renders EventBridge splash', (WidgetTester tester) async {
    await tester.pumpWidget(const EventBridgeApp());
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
