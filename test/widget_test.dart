import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:asmorobangun_app/core/auth_state.dart';
import 'package:asmorobangun_app/main.dart';

void main() {
  testWidgets('Aplikasi bisa dibangun', (WidgetTester tester) async {
    final auth = AuthState();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthState>.value(
        value: auth,
        child: AsmorobangunApp(auth: auth),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}