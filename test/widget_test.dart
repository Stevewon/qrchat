import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qrchat/main.dart';

void main() {
  testWidgets('QRChat app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QRChatApp());

    // Verify splash screen appears
    expect(find.text('QRChat'), findsOneWidget);
    expect(find.text('v7.5.0'), findsOneWidget);
  });
}
