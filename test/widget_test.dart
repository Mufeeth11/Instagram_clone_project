import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:instagram_clone/core/services/storage_service.dart';
import 'package:instagram_clone/views/authentication/login_screen.dart';
import 'package:instagram_clone/views/splash/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  testWidgets('splash renders brand and login screen renders form',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: SplashScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('Capture. Share. Connect.'), findsOneWidget);

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: LoginScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Log in'), findsWidgets);
    expect(find.text('Continue with demo account'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('login validation shows errors for empty fields', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: LoginScreen()),
    ));
    await tester.tap(find.widgetWithText(FilledButton, 'Log in').first);
    await tester.pumpAndSettle();
    expect(find.text('Username or email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
