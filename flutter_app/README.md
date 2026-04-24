# water_quality_companion

Flutter app for the Pebble prototype. The UI is currently organized around three core pages:

- `Home`
- `Map`
- `Ask`

These screens are implemented from the latest Figma handoff and use shared glassmorphism styling, local image assets, and a custom bottom navigation shell.

## Run

```powershell
..\flutter\bin\flutter.bat pub get
..\flutter\bin\flutter.bat run
```

## Verify

```powershell
..\flutter\bin\flutter.bat analyze
..\flutter\bin\flutter.bat test
```

## Main folders

- `lib/app/`: app shell and navigation
- `lib/pages/`: `Home`, `Map`, and `Ask`
- `lib/widgets/`: shared UI building blocks
- `lib/theme/`: colors, shadows, radii, and theme setup
- `assets/`: local Figma-derived images

## Version Log

### 1.0.1+2

- Updated Home page layout to a two-column masonry card arrangement with consistent spacing.
- Aligned Home page card typography, glass fills, progress rings, and icon assets with the Figma design.
- Added the Figma battery SVG asset and centered the Your Device main image.
