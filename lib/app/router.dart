import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../views/authentication/login_screen.dart';
import '../views/create_post/create_post_screen.dart';
import '../views/home/post_detail_screen.dart';
import '../views/messages/messages_screen.dart';
import '../views/notifications/notifications_screen.dart';
import '../views/profile/profile_screen.dart';
import '../views/settings/settings_screen.dart';
import '../views/splash/splash_screen.dart';
import '../controllers/auth_controller.dart';
import 'main_shell.dart';

/// Shared slowed transition used by every route in go_router 18.x, where the
/// router itself has no global pageBuilder and each GoRoute provides its page.
CustomTransitionPage<void> _animatedPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 380),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final incoming = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final outgoing = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: Tween<double>(begin: 1, end: .97).animate(outgoing),
        child: FadeTransition(
          opacity: incoming,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(.06, 0),
              end: Offset.zero,
            ).animate(incoming),
            child: ScaleTransition(
              scale: Tween<double>(begin: .985, end: 1).animate(incoming),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loggedIn = ref.read(authControllerProvider).isLoggedIn;
      final location = state.matchedLocation;
      if (!loggedIn && location != '/login' && location != '/splash') {
        return '/login';
      }
      // Always let the splash screen play on app start / hot restart.
      // It navigates to /main or /login when its animation finishes.
      if (loggedIn && location == '/login') {
        return '/main';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            _animatedPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _animatedPage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/main',
        pageBuilder: (context, state) =>
            _animatedPage(state, const MainShell()),
      ),
      GoRoute(
        path: '/profile/:userId',
        pageBuilder: (context, state) => _animatedPage(
          state,
          ProfileScreen(
            userId: state.pathParameters['userId'],
            initialTab: state.extra is String ? state.extra as String : null,
          ),
        ),
      ),
      GoRoute(
        path: '/post/:postId',
        pageBuilder: (context, state) => _animatedPage(
          state,
          PostDetailScreen(postId: state.pathParameters['postId'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            _animatedPage(state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) =>
            _animatedPage(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: '/messages',
        pageBuilder: (context, state) => _animatedPage(
          state,
          MessagesScreen(
            initialUserId: state.extra is String ? state.extra as String : null,
          ),
        ),
      ),
      GoRoute(
        path: '/create',
        pageBuilder: (context, state) =>
            _animatedPage(state, const CreatePostScreen()),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});
