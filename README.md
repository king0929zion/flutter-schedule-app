# Schedule App Flutter Android

A complete Flutter Android recreation of the uploaded schedule UI prototype, now rendered as a real full-screen app without the demo phone shell, fake status bar, notch, time, signal or battery overlays.

## What is implemented

- Full-screen Flutter Android UI with the original warm grey background and schedule layout.
- Today and Calendar views with animated switching.
- Today hero date section with New York and United Kingdom clocks.
- Bottom task sheet, task cards, avatars, type icons, theme colors and per-type footers.
- Timed schedule, all-day, to-do and note task types.
- Calendar day cards with horizontal event slots.
- Tap feedback, long-press add menu, haptic feedback and staggered fade-up card animations.
- Bottom sheet editor with task type chips, title, description, date/time pickers, inline category dropdown, badge/duration and delete action.
- Image-task flow with dashed upload box and gallery picker feedback.
- AI create flow with local mock parsing, preview and confirm-add behavior.
- In-app toast bubble and blurred context overlay.
- Liquid glass styling through `liquid_glass_renderer` on key controls: navigation chips, add button, reminder chip, task badges, type chips, calendar event pills, context menu and bottom sheets.
- Android manifest opts into Impeller for shader-backed glass rendering on devices where Flutter supports it.

## Run

```bash
flutter pub get
flutter run -d android
```

For older Flutter channels, you can also explicitly run with Impeller:

```bash
flutter run -d android --enable-impeller
```

## Build APK

```bash
flutter build apk --release
```

## Notes

- AI creation is implemented as a local mock parser, matching the prototype behavior rather than calling a remote service.
- Avatar images use network URLs, so the Android project includes INTERNET permission.
- Image picking uses image_picker and Android media permissions are included.
- The glass effect is intentionally applied to small, high-value UI surfaces to keep the shader workload reasonable.
