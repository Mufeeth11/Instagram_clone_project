import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class InstagramApp extends ConsumerWidget {
  const InstagramApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appProvider.select((s) => s.themeMode));
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Instagram Clone',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      builder: (context, child) =>
          SafeArea(child: child ?? const SizedBox.shrink()),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
    );
  }
}
