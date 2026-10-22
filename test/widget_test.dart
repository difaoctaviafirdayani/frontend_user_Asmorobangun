import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:asmorobangun_app/core/auth_state.dart';
import 'package:asmorobangun_app/main.dart';

void main() {
<<<<<<< HEAD
  testWidgets('Aplikasi bisa dibangun', (WidgetTester tester) async {
=======
  testWidgets('App builds without crashing', (WidgetTester tester) async {
>>>>>>> 4587ffe (Update gambar dan tampilan beranda)
    final auth = AuthState();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthState>.value(
        value: auth,
        child: AsmorobangunApp(auth: auth),
      ),
    );
<<<<<<< HEAD
=======
    await tester.pump();
>>>>>>> 4587ffe (Update gambar dan tampilan beranda)

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}