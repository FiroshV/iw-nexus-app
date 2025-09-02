import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:iw_nexus/login_page.dart';
import 'package:iw_nexus/providers/auth_provider.dart';

void main() {
  testWidgets('Login page displays basic elements', (WidgetTester tester) async {
    // Build just the login page with mock provider to avoid API calls during testing
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(),
          ),
        ],
        child: MaterialApp(
          home: const LoginPage(),
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF272579)),
            useMaterial3: true,
          ),
        ),
      ),
    );

    // Wait for the UI to settle
    await tester.pump();

    // Basic verification that the login page loads
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
    
    // Check for key text elements
    expect(find.text('IW Nexus'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mobile'), findsOneWidget);
  });
}
