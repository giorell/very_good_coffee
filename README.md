# Very Good Coffee

A simple Flutter app for discovering coffee photos. Swipe through random images, browse a responsive gallery, and save your favorites for later. Saved items persist locally using Hive.

## App Pages

- **BrewSwipe (Swipe)** — Swipe **right** to save, **left** to skip. Smooth slide animation, subtle on-screen hints, and background prefetching for instant transitions.
- **Gallery** — Infinite, responsive grid that loads multiple photos at a time. Pull to refresh.
- **Saved** — Your saved images with local persistence (Hive). Tap the trash icon on a tile to remove it.

## How to Run

### Prerequisites

- Flutter 3.x and Dart 3.x installed
- A connected device or emulator (iOS/Android), or a desktop/web target

### Steps

1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Run on a device/emulator (Flutter will prompt for a target if multiple are available):

   ```bash
   flutter run
   ```

   Targets:

   - Android: `flutter run -d android`
   - iOS Simulator: `flutter run -d ios`

3. (Optional) Run tests:
   ```bash
   flutter test
   ```

### Notes

- Images are loaded from `https://coffee.alexflipnote.dev`.
- Saved items persist across restarts using Hive (`favorites` box). If you reinstall or clear app data, saved items will be removed.
