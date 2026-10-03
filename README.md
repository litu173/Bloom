# Bloom Alarm — Flutter build

A calm, gamified wake-up alarm app. This is a Flutter port of the original
React/Figma-Make design, built to the same visual language, flows, and
gamification system.

## Setup

This project was hand-authored (in a sandboxed environment with no Flutter
SDK or Android SDK access) as pure Dart source — it ships `lib/`, `assets/`,
and `pubspec.yaml`, but **not** the native `android/`/`ios/` platform
folders that `flutter create` normally generates. That's a one-time,
one-command fix, folded into both paths below.

### Path A — you have Flutter installed locally (fastest)

```bash
cd smart_alarm_flutter
flutter create . --platforms=android,ios   # backfills android/ + ios/ only; never touches lib/
flutter pub get
flutter build apk --debug                  # fast, installs fine for testing
# or: flutter build apk --release
```

Then with your phone connected over USB (USB debugging enabled):
```bash
flutter install
```
or copy `build/app/outputs/flutter-apk/app-debug.apk` (or `app-release.apk`)
to the phone and open it to install (allow "install from unknown sources" if
prompted).

Requires Flutter 3.19+ (Dart 3.3+), the Android SDK/platform-tools, and a
JDK — the usual Flutter Android setup (`flutter doctor` will tell you what's
missing).

### Path B — no Flutter installed locally

Push this project to a GitHub repo — it includes
`.github/workflows/build-apk.yml`, which on every push (or manually via the
Actions tab → "Run workflow") does exactly the `flutter create .` → `flutter
pub get` → `flutter build apk --release` sequence above in GitHub's cloud
runners, then uploads the resulting `.apk` as a downloadable build artifact.
No local Flutter/Android SDK needed — just download the artifact from the
Actions run and install it on your device.

(Codemagic and other Flutter-focused CI services work the same way if you'd
rather not use GitHub Actions.)

## Project structure

```
lib/
  models/         Alarm, Bedtime, ChallengeType, Stats, Achievements, levels
  services/       storage (SharedPreferences), ringtones/audio, date helpers
  state/          AppState — single ChangeNotifier holding all app state
  theme/          color palettes (dark rose / light cream) + typography
  widgets/        shared UI: bottom sheets, wheel picker, floral background,
                  weekly strip, bedtime card, month calendar
  screens/        Home, Alarm setup, Bedtime, Ringing, Challenge, Success,
                  Insights, Wind-down
```

## Before shipping — required follow-ups

This port focuses on faithfully reproducing the UI, flows, and gamification
logic. Three things are stubbed and need real implementation before App
Store / Play Store submission:

### 1. Audio assets
`lib/services/ringtones.dart` expects files at `assets/sounds/<id>.mp3` for
each ringtone id (`bloom`, `radar`, `chimes`, `reflection`, `beacon`, `birds`,
`zen`, `piano`). Add short looping melody files there and uncomment the
`assets:` block in `pubspec.yaml`. Until then, sound previews silently no-op
to a system click so the UI stays testable.

### 2. Background/exact alarm scheduling
The current implementation checks the clock once per second **while the app
is in the foreground**, exactly like the original web app. This is fine for
demos but **will not fire alarms when the app is backgrounded or the phone is
locked** — unacceptable for a real alarm app. For production:

- **Android**: use `flutter_local_notifications` (already a dependency) with
  `AndroidScheduleMode.exactAllowWhileIdle` and the `SCHEDULE_EXACT_ALARM` /
  `USE_EXACT_ALARM` permission, or a dedicated plugin such as
  `android_alarm_manager_plus` for a true foreground alarm service with a
  full-screen intent (so the ringing screen shows over the lock screen).
- **iOS**: iOS does not allow arbitrary background execution for custom alarm
  UI. Use local notifications with a critical/time-sensitive interruption
  level and a custom notification sound, and accept that the *native*
  notification (not your Flutter ringing screen) is what fires when the app
  isn't running. Full custom lock-screen alarm UI on iOS generally requires
  a private entitlement Apple grants only to a small set of apps — plan
  your UX around standard notifications + `UNUserNotificationCenter` sounds.
- Register alarms with the OS scheduler whenever `AppState.saveAlarm` /
  `deleteAlarm` / `updateBedtime` runs, not just via the in-app timer.

### 3. Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```
Add to `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```
Request notification permission at first launch via
`flutter_local_notifications`'s iOS/Android initialization.

## What's fully implemented

- All 8 screens (Home, Alarm setup, Bedtime, Ringing, Challenge, Success,
  Insights, Wind-down) with matching layout, copy, and dark/light theming.
- Full alarm CRUD, repeat-day logic, "delete after ring" / one-off alarms.
- Bedtime schedule with wind-down reminder trigger.
- All 4 wake-up challenge mini-games (math, memory, tap-sequence, pattern
  puzzle) with the same adaptive-difficulty logic as the original.
- Gamification: XP, 8-level progression, 9 achievements, streak/no-snooze
  tracking, bloom calendar.
- Local persistence via SharedPreferences (alarms, stats, theme, bedtime,
  bloom-day history) — same shape as the original app's storage.ts.
- Snooze flow, vibration, and gradual-volume alarm playback (pending real
  audio assets per above).

See `PRODUCT_SPEC.md` (project root) for full feature/flow documentation.
