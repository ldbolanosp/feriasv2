import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ferias_app/app.dart';

void main() {
  testWidgets('App base boots router shell', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Router<Object>), findsOneWidget);
  });
}
