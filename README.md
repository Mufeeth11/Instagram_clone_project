# Instagram Clone (Flutter, local E2E demo)

A production-styled Instagram-inspired mobile app with a **fully local simulated backend**. No Firebase, no paid APIs, no API keys. All state survives app restarts via `SharedPreferences`.

## Quick start

```bash
flutter pub get
flutter run                       # pick Android device/emulator
```

Demo login:

- Username: `demo_user`
- Password: `demo123`

You can also tap **Continue with demo account** or create a local account from the login screen.

## Build & install the APK

```bash
flutter build apk --release
```

Release APK: `build/app/outputs/flutter-apk/app-release.apk`

Install with adb:

```bash
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

Or copy the APK to an Android phone, enable *Install unknown apps*, and open it.

## Verify

```bash
flutter analyze                   # 0 issues
flutter test                      # data, persistence, widget + navigation flow tests
```

## What works end to end

- Splash → session-aware routing → login / demo login / sign-up / dummy password reset
- Home feed: stories viewer (progress, auto-advance, tap navigation, swipe down), add story, carousel posts, double-tap like, comments, share, save, follow, caption expand, full-screen viewer, pull-to-refresh with new dummy post
- Reels: vertical paging, play/pause, autoplay current reel only, mute, like, comment, save, share, follow, loading/error fallback
- Explore: local search of users/posts/hashtags, history, suggestions, mixed trending grid
- Profile: posts / reels / tagged / saved tabs, followers & following sheets, edit profile (gallery or sample avatars), follow/message
- Create post: gallery pick with graceful fallback, sample images, caption + hashtags, location, publish into feed and profile
- Settings: account, theme (light/dark/system), language, privacy toggles, blocked users, comment controls, dummy legal pages, password change, confirm logout
- Messages and notifications with locally stored threads and simulated replies

## Architecture

```
lib/
├── main.dart
├── app/            View: app.dart, router.dart, main_shell.dart, theme/
├── controllers/    Controller: auth, feed, story, reels, explore, profile,
│                   messages, notifications, settings, navigation
├── views/          View: splash, authentication, home, stories, reels,
│                   explore, profile, settings, create_post, notifications,
│                   messages, widgets/
├── models/         Model: user, post, reel, story, comment, notification, chat
├── data/           Model: dummy_data/, repositories/, local/
├── core/           Model/infrastructure: services/, storage/, utils/
└── state/          Model: app_state.dart (Riverpod notifier + persistence)
```

MVC flow: every screen and widget in `views/` reads state and triggers actions through `controllers/`; controllers delegate to the unchanged persisted model store in `state/` and the entities/services in `models/`, `data/` and `core/`. No view talks to `appProvider` directly.

Key libraries: Flutter Material 3, Riverpod 3, GoRouter 18, SharedPreferences, video_player, image_picker, cached_network_image, Lottie, liquid_pull_to_refresh.

## Local persistence

One JSON blob under the SharedPreferences key `instagram_clone_state_v1` stores: login session, local accounts/passwords, profile edits, created posts, likes, comments, saves, follows, viewed stories, blocked users, search history, chat messages, theme and settings.

## Known limitations

- Images and sample videos are loaded from free public sources (`picsum.photos` and Google's public sample video bucket), so media needs an internet connection. The app degrades to placeholders/error widgets when offline.
- The "backend" is simulated entirely on-device; there is no cross-device sync or real authentication.
- Language selection is persisted but only changes the setting label (no full localisation yet).
- Archive and policy pages are informational demos.
- iOS builds require macOS + Xcode; this workspace built the Android APK on Windows.
- Kotlin incremental compilation is disabled in `android/gradle.properties` because the project (F:) and pub cache (C:) are on different drives; re-enable it if both live on the same drive.
