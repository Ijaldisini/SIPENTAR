import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sipentar/main.dart';

void main() {
  testWidgets('SIPENTAR root application builds', (WidgetTester tester) async {
    const testHome = Scaffold(body: Center(child: Text('SIPENTAR test home')));

    await tester.pumpWidget(const MyApp(homeOverride: testHome));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final routes = app.routes;

    expect(app.title, 'Sipentar');
    expect(find.text('SIPENTAR test home'), findsOneWidget);
    expect(routes, isNotNull);
    expect(routes?.containsKey('/dashboard'), isTrue);
    expect(routes?.containsKey('/budidaya'), isTrue);
  });
}
