import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:instagram_clone/core/services/storage_service.dart';
import 'package:instagram_clone/models/post_model.dart';
import 'package:instagram_clone/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dummy data, interactions and local persistence work end to end', () async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();

    final container = ProviderContainer();
    addTearDown(container.dispose);
    var state = container.read(appProvider);
    expect(state.users.length, greaterThanOrEqualTo(20));
    expect(state.posts.length, greaterThanOrEqualTo(30));
    expect(state.reels.length, greaterThanOrEqualTo(15));
    expect(state.comments.length, greaterThanOrEqualTo(20));
    expect(state.stories.length, greaterThanOrEqualTo(15));

    final notifier = container.read(appProvider.notifier);
    expect(notifier.login('demo_user', 'wrong'), isNotNull);
    expect(notifier.login('demo_user', 'demo123'), isNull);
    state = container.read(appProvider);
    expect(state.isLoggedIn, isTrue);
    expect(state.currentUser!.username, 'demo_user');

    notifier.toggleLikePost('p1');
    expect(container.read(appProvider).likedPosts.contains('p1'), isTrue);
    notifier.toggleSavePost('p1');
    expect(container.read(appProvider).savedPosts.contains('p1'), isTrue);
    notifier.addComment(
        targetId: 'p1', targetType: 'post', text: 'A local comment');
    expect(container.read(appProvider).commentCountFor('p1'),
        greaterThanOrEqualTo(1));
    notifier.toggleFollow('u12');
    expect(container.read(appProvider).isFollowing('u12'), isTrue);
    notifier.updateProfile(displayName: 'Renamed Demo', bio: 'Persisted bio');
    notifier.setTheme(ThemeMode.dark);
    notifier.addSearch('flutter');
    notifier.addPost(PostModel(
      id: 'p_test',
      userId: state.currentUserId!,
      caption: 'Created locally',
      imageUrls: const ['https://picsum.photos/seed/test/600/600'],
      createdAt: DateTime.now(),
      isCreatedByUser: true,
    ));

    // Allow the fire-and-forget SharedPreferences write to settle.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final saved = StorageService.instance.readState();
    expect(saved, isNotNull);
    expect(saved!['currentUserId'], 'u0');
    expect(saved['themeMode'], ThemeMode.dark.index);

    final restarted = ProviderContainer();
    addTearDown(restarted.dispose);
    final restored = restarted.read(appProvider);
    expect(restored.isLoggedIn, isTrue);
    expect(restored.currentUser!.displayName, 'Renamed Demo');
    expect(restored.themeMode, ThemeMode.dark);
    expect(restored.likedPosts.contains('p1'), isTrue);
    expect(restored.savedPosts.contains('p1'), isTrue);
    expect(restored.isFollowing('u12'), isTrue);
    expect(restored.searchHistory, contains('flutter'));
    expect(restored.posts.first.id, 'p_test');

    restarted.read(appProvider.notifier).logout();
    expect(restarted.read(appProvider).isLoggedIn, isFalse);
  });
}
