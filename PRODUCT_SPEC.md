# Bloom — Product & Design Specification

A calm, gamified alarm app that wakes people gently with light cognitive
challenges instead of a jarring blare, and rewards consistency with a soft
XP/streak/achievement system built around a floral "bloom" metaphor.

Platform: iOS & Android (Flutter). Visual style ported 1:1 from the original
Figma Make design.

---

## 1. Product pillars

1. **Gentle over jarring** — gradual volume, pre-alarms, soft copy ("A gentle
   moment", "Rest a little more") instead of urgency and pressure.
2. **Cognitive engagement, not just noise** — a short challenge (math,
   memory, tap-sequence, or pattern puzzle) must be solved to fully dismiss
   the alarm, which research-backed alarm apps use to break the
   snooze-and-fall-back-asleep cycle.
3. **Progress without pressure** — XP, levels, streaks, and achievements
   celebrate consistency but explicitly de-emphasize guilt (see the
   Insights screen's closing note: "Badges are here to celebrate, not to
   chase").
4. **Whole-sleep-cycle care** — the app manages both the wake-up (Alarms)
   and the wind-down (Bedtime schedule + reminder), not just one end of the
   night.

---

## 2. Information architecture

```
Home (root)
 ├─ Add / Edit Alarm  (modal — full-screen sheet)
 │   ├─ Repeat picker (sheet)
 │   ├─ Sound picker (sheet)
 │   └─ Challenge picker (sheet)
 ├─ Bedtime  (screen)
 │   ├─ Fall-asleep time picker (sheet)
 │   ├─ Wake-up time picker (sheet)
 │   ├─ Repeat picker (sheet)
 │   ├─ Bedtime reminder picker (sheet)
 │   ├─ Sound picker (sheet)
 │   └─ Challenge picker (sheet)
 ├─ Insights / "Your rhythm"  (screen)
 │   └─ Month calendar, achievements grid
 └─ Wind-down  (full-screen moment, triggered by reminder or manually)

Alarm firing flow (overlays, not reachable via nav):
 Ringing → Challenge → Success → back to Home
```

---

## 3. Data model

| Entity | Fields |
|---|---|
| **Alarm** | id, time (`HH:MM`), label, days (`0=Sun..6=Sat`, empty = one-off), enabled, preAlarm, gradualVolume, vibrate, deleteAfter, challenge (`math\|memory\|tap\|puzzle`), ringtone id |
| **Bedtime** | sleep time, wake time, days, enabled, reminder (minutes before sleep, 0 = none), ringtone, gradualVolume, vibrate, challenge |
| **Stats** | xp, streak, totalWakes, perfectCount, noSnoozeStreak, counts per challenge type, earliestWakeMinutes |
| **Achievement** | id, name, description, icon, color, earned-predicate over (Stats, level) |

**Persistence**: all state is stored locally (key-value store — SharedPreferences
in the Flutter build, localStorage in the original web build). No backend;
this is a fully offline, single-device app in its current scope.

---

## 4. Screens

### 4.1 Home
**Purpose**: at-a-glance view of the wake-up rhythm and quick access to
everything else.

**Layout (top to bottom)**:
- Greeting header ("Good morning, {name}") + page title ("Rest easy
  tonight") + theme toggle + add-alarm button (top right, primary-filled
  circle).
- **This week** strip — 7 dots (Sun–Sat), today ringed, past days filled
  with a 🌸 bloom if the user woke gently that day, future days dimmed.
  Tapping opens Insights.
- **Level chip** — circular XP progress ring + level name + current streak
  + "X XP to next bloom" copy. Tapping opens Insights.
- **Next gentle wake** hero card — large time display + challenge type,
  shown only if an alarm is enabled. Gradient background (rose → berry).
- **Bedtime card** — collapsed summary of the sleep schedule (fall-asleep /
  wake-up times, duration) or "Off" if disabled. Tapping opens Bedtime.
- **Alarm list** — enabled alarms first, sorted by soonest-to-fire; each row
  shows time, label, active repeat days (highlighted), and a toggle switch.
  Tapping a row opens it for editing.
- **Preview a gentle wake-up** pill button — triggers the ringing flow
  immediately using the first enabled alarm, without consuming/disabling it,
  for demoing the experience.
- **Wind down now** pill button — jumps straight to the Wind-down screen.

**Interactions**:
- Toggle switch flips `enabled` instantly, no confirmation.
- Theme toggle switches dark ⇄ light instantly with persisted preference.

### 4.2 Add / Edit Alarm
Presented as a full-screen modal (Cancel / title / Save nav bar).

- **Time wheel** — iOS-style 3-column drum roll (hour, minute, AM/PM).
- **Label** field — free text, right-aligned, 30-char max, placeholder is
  the auto-generated poetic label for the current repeat schedule (e.g.
  "Weekday sunrise" for Mon–Fri).
- **Repeat** row → opens Repeat sheet: presets (Once / Daily / Weekdays) +
  a 7-dot custom day toggle row. Changing days auto-refreshes the label
  *only if* the label hasn't been manually edited away from an
  auto-generated one.
- **Sound** row → opens Sound sheet: System/Device grouped list, tap a row
  to select + preview, tap the play icon to preview without selecting.
- **Wake-up challenge** row → opens Challenge sheet: 4 options (Gentle math
  / Tap the blooms / Little puzzle / Remember the number), each with a
  one-line description of what it involves.
- **Toggles**: Soft pre-alarm (whisper of sound 5 min early), Gradual
  volume (rises over ~20s), Vibrate, Delete after alarm goes off (for
  single-use alarms).
- **Delete Alarm** (edit mode only) — destructive, immediate (no confirm
  dialog in the current build; add one before shipping if desired).

### 4.3 Bedtime
Full screen, same visual language as Alarm setup but scoped to the sleep
schedule.

- **Sleep schedule** toggle — master on/off. All settings below only render
  when enabled (this is the one place the design explicitly hides
  complexity behind a switch rather than disabling it visually).
- **Fall asleep** / **Wake up** time rows → open the same time-wheel sheet
  as Alarm setup.
- **Repeat**, **Bedtime reminder** (0/5/10/15/30/45/60 min before sleep
  time), **Sound**, **Wake-up challenge** — same pattern as Alarm setup.
- **Gradual volume** / **Vibrate** toggles for the wake-up side.
- Footer note reminding the user the wake-up still uses a gentle challenge.

**Behavior**: the bedtime schedule contributes a *second* virtual alarm
(id `bedtime-wake`) to the scheduler, built from its wake-up settings, and
independently fires a **wind-down reminder** at `sleep time − reminder`.

### 4.4 Ringing
Full-screen overlay when an alarm fires (or is previewed).

- Floral background with drifting petal particles.
- Alarm label + time, large serif display.
- Breathing orb — 3 concentric pulsing rings behind a central "Begin /
  breathe in" button. Tapping it moves to the Challenge screen (this is
  the only way to proceed — there's no way to dismiss without solving a
  challenge, by design).
- **Snooze** button — "Rest a little more · N left" (max 2 snoozes),
  disabled once exhausted. Each snooze: stops sound/vibration, schedules a
  5-minute re-ring, docks 1 from the current streak (gentle penalty), and
  returns to Home in the interim.

### 4.5 Challenge
Full screen. Renders one of 4 mini-games based on the firing alarm's
`challenge` setting, at a difficulty (1–3) that adapts run-to-run: +1 on a
perfect (first-try, no mistakes) solve, −1 on any mistake, clamped 1–3.

| Game | Mechanic | Difficulty scaling |
|---|---|---|
| **Gentle math** | 3 rounds of two-number addition, pick the correct sum from 4 options | Operand cap: 6 / 12 / 20 |
| **Remember the number** | Number shown for 3s, then recall via numeric keypad | 4 digits (levels 1–2) / 5 digits (level 3) |
| **Tap the blooms** | Watch a sequence of glowing petals, repeat it by tapping | Sequence length: 3 / 4 / 5 |
| **Little puzzle** | A repeating color pattern with one blank; pick the bloom that continues it | Pattern length: 2 / 3 / 3 |

A wrong answer at any point clears "perfect" for that wake (still solvable,
just no bonus XP) and, for math/puzzle, shakes the wrong option. On
completion, `onComplete(perfect)` fires and the app moves to Success.

### 4.6 Success
Full-screen celebration, floral background with petals.

- Rotating bloom badge illustration.
- "Good morning" + one of 4 rotating affirmation lines (random per wake).
- Streak chip: "🌸 N in bloom" + "+XP" gained this wake.
- If perfect: "Clear-minded on the first try · {level name}".
- If a new achievement was earned this wake: badge chip with its name.
- "Start the day" button → returns to Home.

**XP awarded**: `10` base + `8` bonus if perfect. Streak +1, total wakes +1,
perfect count +1 if applicable, per-challenge-type count +1,
`noSnoozeStreak` resets to 0 if any snooze was used this wake else +1,
`earliestWakeMinutes` updated if this is the earliest wake on record. The
day is marked bloomed on the calendar.

### 4.7 Insights ("Your rhythm")
Full screen, reachable from Home's weekly strip or level chip.

- Level card: big progress ring, level name, XP, linear progress bar,
  "X XP to next bloom".
- 3 stat tiles: Streak (days), Wakes (total), Clear (first-try count).
- **Month calendar** — real current month, 🌸 on days woken gently
  (excludes future days, which are dimmed), today ringed.
- **Achievements grid** — 9 achievements, 2 columns, locked ones shown
  dimmed with a lock icon instead of their real icon.
- Closing "soft note" callout reinforcing the no-pressure philosophy.

### 4.8 Wind-down
Full-screen moment, triggered automatically at the bedtime reminder time
(if bedtime schedule is enabled) or manually via Home's "Wind down now".

- Breathing moon icon.
- "Time to wind down" + one of 5 rotating calming messages (cycles every
  4.5s).
- 3 static tips: silence phone / set the internet aside / dim screen.
- Footer: "Wake-up set for {time}" + "Good night" button → returns Home.
- A single gentle chime plays on entry.

---

## 5. Gamification system

### Levels (cumulative XP thresholds)
Seedling (0) → Sprout (30) → Bud (80) → Bloom (150) → Blossom (250) →
Wildflower (400) → Garden (600) → Meadow (900, max).

### XP
- +10 per completed wake.
- +8 bonus if solved perfectly (no wrong attempts).

### Achievements (9)
| Achievement | Condition |
|---|---|
| First Bloom | Complete first wake |
| Clear Dawn | Solve a challenge first-try |
| Early Riser | Wake at/before 6:30 AM |
| Week in Bloom | 7-day streak |
| Math Mind | 10 gentle-math wakes |
| Memory Master | 10 memory wakes |
| Green Thumb | At least 1 wake of every challenge type |
| Snooze-Free | 7 wakes in a row with no snooze |
| Full Blossom | Reach level 5 (Blossom) |

### Streak mechanics
- +1 per completed wake.
- −1 (min 0) per snooze used, applied immediately on snooze (not deferred
  to the wake outcome).

---

## 6. Visual design system

### Palette (dark, default)
| Token | Hex | Use |
|---|---|---|
| Background | `#191115` | App background |
| Card | `#241A1F` | Cards, sheets |
| Primary | `#F2506E` | Buttons, active states, progress |
| Foreground | `#F4E9EC` | Primary text |
| Muted foreground | `#BD97A2` | Secondary text |
| Accent | `#3A2530` | Callout backgrounds |
| Border | `#FFD6E0` @ 12% | Card/divider borders |
| Calm rose / pink / berry / mist | `#FF6E8C` / `#E8637F` / `#8F3350` / `#2C1D23` | Accent surfaces, day dots, gradients |

### Palette (light)
Warm cream/dusty-rose alternative — background `#FBF7F1`, primary
`#B98A8F`, card `#FFFDFA`, muted foreground `#A2938C`. Same structural
tokens, softer/lower-contrast mood for daytime use.

### Typography
- **Body**: Quicksand (rounded, friendly, medium weight default) — all UI
  chrome, labels, buttons.
- **Display/serif accent**: Fraunces — used sparingly for large numerals
  (next-alarm time, challenge numbers) and emotional copy ("Good morning",
  "Time to wind down") to give warmth without looking twee everywhere.

### Shape & motion language
- Large corner radii throughout (20–34px) — cards, sheets, buttons all read
  as soft/organic, never sharp.
- Bottom sheets: iOS-native pattern (grabber handle, Cancel · title · Done
  nav bar, spring-up transition).
- Floral motif: low-opacity corner blooms as ambient texture on Home-adjacent
  screens; full drifting-petal animation only during Ringing/Success to mark
  those as emotionally significant moments.
- Breathing/pulsing animation (scale + opacity loop, ~6s) used for the
  Ringing orb and Wind-down moon — reinforces the "slow your breathing"
  message kinesthetically, not just verbally.

---

## 7. User flows

### 7.1 Morning wake flow (primary loop)
```
[Alarm time reached]
  → Ringing screen (sound + vibration start)
     → tap Begin
  → Challenge screen (adaptive difficulty game)
     → solved
  → Success screen (XP/streak/badge feedback)
     → tap "Start the day"
  → Home (updated streak, bloom day marked, alarm auto-disabled if one-off)
```
Snooze branch: Ringing → tap Rest a little more → Home (idle) → 5 min later
→ Ringing again, up to 2 times, then no more snoozes offered.

### 7.2 Creating an alarm
```
Home → tap + → Add Alarm sheet
  → set time via wheel
  → (optional) edit label
  → Repeat sheet → pick preset or custom days → Done
  → Sound sheet → tap to preview + select → Done
  → Challenge sheet → pick game → Done
  → toggle pre-alarm / gradual volume / vibrate / delete-after as desired
  → tap Save
→ Home (new alarm appears in list, sorted by next-to-fire)
```

### 7.3 Setting up bedtime + wind-down
```
Home → Bedtime card → Bedtime screen
  → toggle Sleep schedule on
  → set Fall asleep / Wake up times
  → set Repeat, Reminder, Sound, Challenge
  → toggle Gradual volume / Vibrate
  → tap Home to return
[reminder time reached, any day in schedule]
  → Wind-down screen appears automatically
  → user reads tips, taps Good night
  → Home
[wake time reached, per bedtime schedule]
  → same Ringing → Challenge → Success flow as a normal alarm
```

### 7.4 Reviewing progress
```
Home → tap weekly strip OR level chip → Insights screen
  → review level progress, stats, month calendar, achievements
  → tap Home to return
```

---

## 8. Non-functional requirements for a real ship

These are called out explicitly because they're the gap between "looks and
behaves right in a demo" and "safe to trust as someone's actual alarm":

1. **Reliable background firing.** The app must schedule real OS-level
   alarms/notifications (see Flutter README → "Before shipping"), not rely
   on an in-app timer that dies when the app is backgrounded or killed.
2. **Do Not Disturb / Silent mode override.** A genuine alarm app needs to
   sound even in silent mode / DND (subject to each OS's alarm-category
   APIs) — critical alerts on iOS, alarm-stream audio focus on Android.
3. **Battery-optimization exemptions** on Android (some OEMs kill background
   schedulers aggressively) — surface an onboarding prompt to whitelist the
   app.
4. **Boot persistence** — alarms must survive a phone restart
   (`RECEIVE_BOOT_COMPLETED` + re-registering schedules).
5. **Accessibility** — the current design leans on color (rose dots, day
   highlights) for state; ensure sufficient contrast and add non-color
   affordances (icons/labels) for colorblind users before shipping widely.
6. **Real audio assets** — see README; synthesized Web-Audio tones from the
   original React build don't have a direct equivalent in this Flutter port
   and were replaced with an asset-file-based player.

---

## 9. Out of scope (for this version)

- Accounts/sync across devices (fully local/offline by design).
- Smart/adaptive wake windows (e.g. sleep-cycle-based wake time nudging).
- Social/sharing features around streaks or achievements.
- Notifications summarizing weekly progress (Insights is pull, not push).
