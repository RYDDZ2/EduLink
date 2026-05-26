import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edulink/screens/auth_screen.dart';

void main() {
  testWidgets('Auth screen can be constructed', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    expect(find.text('EduLink'), findsWidgets);
    expect(find.text('Login'), findsOneWidget);
  });
}
