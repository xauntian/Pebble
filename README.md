# Pebble

Pebble is a Flutter mobile prototype for a water-quality companion app. The main application lives in `flutter_app/`, and the repository also keeps a local Flutter SDK in `flutter/` for Windows-based development.

## Current App

- `Home`: health summary dashboard with average test data, device status, test life, and water quality entry points.
- `Map`: water-location map experience with search, map markers, place cards, and location detail states.
- `Water Quality`: report detail page with region and location filters, a region-aware calendar picker, measurement cards, score visualization, and test history.
- `Ask`: water knowledge Q&A plus AI Search with suggestion chips, typed input, voice prompt state, local response handling, and Done/reset behavior.
- Shared UI: glass cards, pill chips, animated dropdowns, progress rings, top bar, bottom navigation, responsive layout helpers, and local Figma-derived assets.

## Generated Change Summary

- Added structured demo data for device connection state and water test reports.
- Added water-quality domain models and an API abstraction for report loading.
- Built the Water Quality page with location filters, region switching, calendar date selection, score display, measurements, and history.
- Updated the calendar so dates only appear for the currently selected region, and other regions appear only after switching regions.
- Reworked AI Search so the result layer uses the original card container and no longer overflows after Done.
- Expanded Home metric cards and connected the Water Quality card into the detail page.
- Rebuilt Map interactions around searchable water points, map markers, place cards, and rating/status UI.
- Improved navigation, app shell behavior, top bar, pill chip menus, progress ring animation, responsive spacing, and theme colors.
- Added `fl_chart`, `flutter_map`, `http`, and `latlong2` dependencies.
- Added widget tests for navigation, narrow viewport layout, Water Quality calendar behavior, Ask Q&A, AI Search submit, and Done reset.

## Project Structure

- `flutter_app/`: Flutter application source.
- `flutter_app/lib/app/`: app bootstrap and shell.
- `flutter_app/lib/navigation/`: destination definitions, bottom navigation, and shell layout.
- `flutter_app/lib/pages/`: `Home`, `Map`, `Water Quality`, and `Ask` pages.
- `flutter_app/lib/widgets/`: shared cards, chips, navigation controls, progress rings, and map/search widgets.
- `flutter_app/lib/models/`: app snapshot, device connection, and water test report models.
- `flutter_app/lib/data/`: local demo data for device and water reports.
- `flutter_app/lib/services/`: local AI response and water report service abstractions.
- `flutter_app/lib/theme/`: colors, spacing, radius, shadows, typography, theme setup, and responsive layout helpers.
- `flutter_app/assets/`: local Figma-derived assets and fonts.
- `flutter/`: local Flutter SDK.

## Run Locally

```powershell
cd flutter_app
..\flutter\bin\flutter.bat pub get
..\flutter\bin\flutter.bat run
```

## Verify

```powershell
cd flutter_app
..\flutter\bin\flutter.bat analyze
..\flutter\bin\flutter.bat test
```

## Build APK

```powershell
cd flutter_app
..\flutter\bin\flutter.bat build apk --release
```

The release APK is generated at `flutter_app/build/app/outputs/flutter-apk/app-release.apk`.

Full application development was completed with Codex.
