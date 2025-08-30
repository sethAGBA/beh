import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beh/router.dart'; // Import the router
import 'package:provider/provider.dart'; // Import provider for UserProvider
import 'package:beh/user_provider.dart'; // Import UserProvider

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => UserProvider(),
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that the MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}