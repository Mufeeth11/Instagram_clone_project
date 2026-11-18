import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:instagram_clone/app/app.dart';
import 'package:instagram_clone/core/services/storage_service.dart';
import 'package:instagram_clone/features/explore/explore_screen.dart';
import 'package:instagram_clone/features/home/home_screen.dart';
import 'package:instagram_clone/features/profile/profile_screen.dart';
import 'package:instagram_clone/features/reels/reels_screen.dart';
import 'package:instagram_clone/features/settings/settings_screen.dart';
import 'package:instagram_clone/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash → demo login → tabs → settings → theme → logout',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();

    await tester.pumpWidget(const ProviderScope(child: InstagramApp()));
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Continue with demo account'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Continue with demo account'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Search'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ExploreScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Reels'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ReelsScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Profile'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ProfileScreen), findsWidgets);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.scrollUntilVisible(
      find.widgetWithText(ListTile, 'Theme Settings'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Theme Settings'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Dark mode'));
    await tester.pump(const Duration(milliseconds: 200));
    final container = ProviderScope.containerOf(
        tester.element(find.byType(InstagramApp)));
    expect(container.read(appProvider).themeMode, ThemeMode.dark);
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark);

    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'Log out'),
      1200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Log out'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Continue with demo account'), findsOneWidget);
    expect(container.read(appProvider).isLoggedIn, isFalse);
  });
}
