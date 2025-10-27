# Water Color Sort Puzzle

Water Color Sort Puzzle is a vibrant pouring puzzler built with Flutter and the Flame game engine. Players tap bottles to pour stacks of liquid color, matching shades to clear each stage. A full 300-level campaign, evolving bottle silhouettes, and progression hooks make it ready to grow into a polished mobile release.

## Features

- Flame-powered game board with tappable bottles and satisfying pour animations
- 300 handcrafted, solvable levels generated from JSON files in `assets/levels`
- Difficulty curve that ramps from gentle practice pours to brain-bending late-game mixes
- Bottle silhouettes upgrade every 50 levels, keeping visuals feeling fresh and rewarding
- Provider-based app state that tracks unlocks, stars, and sound settings
- Audio service ready for SFX playback (using placeholder assets)
- HUD, pause, and level-complete overlays implemented in Flutter UI
- Firebase service scaffolding for anonymous auth, cloud saves, and leaderboards
- Continuous integration via GitHub Actions running `flutter analyze` and `flutter test`
- Level generation utility in `tool/generate_levels.py` to rebuild the campaign deterministically

## Project structure

```
lib/
├─ main.dart
├─ src/
│  ├─ data/level_model.dart
│  ├─ game/
│  │  ├─ crayon_game.dart
│  │  ├─ components/
│  │  │  ├─ tube_component.dart
│  │  │  ├─ tube_style.dart
│  │  │  └─ color_segment.dart
│  │  └─ systems/pour_system.dart
│  ├─ services/
│  │  ├─ audio_service.dart
│  │  ├─ firebase_service.dart
│  │  └─ storage_service.dart
│  ├─ state/app_state.dart
│  └─ ui/
│     ├─ home_screen.dart
│     ├─ game_screen.dart
│     ├─ level_select.dart
│     └─ overlays/
│        ├─ hud_overlay.dart
│        ├─ pause_overlay.dart
│        └─ level_complete.dart
assets/
├─ audio/
├─ images/
├─ fonts/
└─ levels/
tool/
└─ generate_levels.py
```

## Getting started

1. Install Flutter (3.3 or newer) and ensure `flutter doctor` passes.
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the game on an emulator or device:
   ```bash
   flutter run
   ```

### Running tests

```bash
flutter test
```

### Firebase setup

The Firebase integration is optional but scaffolded. To enable cloud saves and leaderboards:

1. Create a Firebase project and add Android/iOS apps.
2. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS). Place them in the respective native project folders. These files are intentionally ignored by Git.
3. Enable Anonymous Auth (and additional providers as needed) and create Firestore collections `users` and `leaderboards` using the schema described in `lib/src/services/firebase_service.dart`.

### Assets

Audio, image, and font files are placeholders. Replace them with production-ready assets while keeping the same directory structure or updating `pubspec.yaml` accordingly.

## Continuous integration

The GitHub Actions workflow in `.github/workflows/flutter-ci.yml` installs Flutter, analyzes the code, and runs tests on every push and pull request.

## Contributing

1. Fork the repository and create a feature branch.
2. Run `flutter format`, `flutter analyze`, and `flutter test` before committing.
3. Open a pull request describing your changes.

Enjoy building on Water Color Sort Puzzle!
