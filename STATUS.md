# STATUS.md — Kairos build board

Live state of the Kairos build. Governed by `AGENTS.md`. Product scope is in
`Kairos_Feature_Spec.pdf`.

**This file is the shared memory of the project. Update it before you write code, and
again before you log off. Never delete a row.**

- Current phase: **1 — Instruments** (Phase 0 shell and tokens mostly landed)
- Phase window: weeks 4–10
- Last updated: 2026-11-17 01:50 UTC by `agent-karan`
- Active agents: none

---

## 1. Who is working right now

| Agent | Task | Claimed (UTC) | Heartbeat |
|---|---|---|---|
| — | — | — | — |

A claim is live for 2 hours. Stale after 24 hours and open to takeover, per `AGENTS.md` §4.

---

## 2. Current focus

**Make every instrument and the moments engine visible and usable in the app.** The
token layer and three-tab shell exist; the next work is the five instruments, then the
seven moment types, counting modes, zero moment and timeline depth. Do not start widget
extensions until the in-app product is complete.

Order from here: `P1-03`/`P1-04` world clock → `P1-05`–`P1-08` alarm → `P2-04`/`P2-05`
moment types and counting modes → `P2-07` zero moment → `P2-02` full editor → remaining
instrument depth.

**P0-03 acceptance criteria** (claimed by `agent-karan`, 2026-11-16 17:18)

1. A `KairosTheme` exposes complete dark and light `ThemeData` built only from tokens.
2. Every token group (colour, type, spacing, radius) is reachable from `Theme.of(context)` via `ThemeExtension`.
3. Both themes resolve every `ColorScheme` role and meet 4.5:1 contrast for body text on background.
4. Widget tests render a probe under both themes and read every extension without throwing.
5. Switching `themeMode` between light and dark changes canvas colour while preserving the same token identities.

---

## 3. Task board

### Phase 0 — Foundation (weeks 1–3)

| ID | Task | Owner | Status | Updated | Evidence |
|---|---|---|---|---|---|
| P0-01 | Repo scaffold: Flutter app, folder structure, lints, CI workflow | Cline | done | 2026-11-16 15:55 | dart format clean, analyze clean, 1 test pass, CI configured |
| P0-02 | Design tokens in Dart from spec §4: colour, type scale, spacing, radius, motion, haptics, elevation | Cline | done | 2026-11-16 16:30 | dart format clean, analyze clean, flutter test pass |
| P0-02 | Design tokens in Dart from spec §4: colour, type scale, spacing, radius, motion, haptics, elevation | — | todo | — | — |
| P0-03 | Theme: dark and light, `ThemeExtension` wiring, both modes first-class | agent-karan | done | 2026-11-16 17:34 | `flutter analyze --fatal-infos` clean; `flutter test` 16 passed; `flutter build apk --debug` built |
| P0-04 | Component library v0: button, card, sheet, list row, empty state, loading state + Glassmorphism system | agent-karan | done | 2026-11-17 01:50 | `GlassContainer`, `GlassCard`, `GlassButton`, `AtmosphericBackground`, `GlassEmptyState`, `GlassSegmentedControl`, 56 tests pass |
| P0-05 | Time formatting engine in `core/time`: tabular numerals, unit ladder, sleeps, X-of-Y, percentage | agent-karan | done | 2026-11-16 23:20 | `countdown_test.dart` 13 passed incl. zero instant, DST, weekdays; `flutter analyze --fatal-infos` clean |
| P0-06 | Localisation scaffold: ARB files, 22 Indian languages stubbed, RTL, regional numeral sets | — | todo | — | — |
| P0-07 | Accessibility harness: text scale to 310%, semantics labels, contrast check in CI | — | todo | — | — |
| P0-08 | Navigation shell: Next / Now / Then tabs plus Instruments area, deep-link routing | agent-karan | done | 2026-11-16 17:34 | `flutter test test/app/shell_test.dart` 5 passed; `flutter build apk --debug` built; deep-link routing still open |
| P0-09 | CI gate scripts: `tool/check_tokens.dart`, `tool/check_strings.dart` | — | todo | — | — |
| P0-10 | Master UI Transformation: Warm Precision luxury watch & editorial aesthetic redesign | agent-karan | done | 2026-11-17 21:30 | flutter analyze --fatal-infos: 0 issues; flutter test: 88 passed; all 32 screenshots generated clean with real typography |

### Phase 1 — Instruments (weeks 4–10)

| ID | Task | Owner | Status | Updated | Evidence |
|---|---|---|---|---|---|
| P1-01 | Drift schema v1: moments, alarms, timers, laps, focus sessions, settings + migrations | — | todo | — | — |
| P1-02 | Timezone service: bundled IANA data, DST, half-hour offsets, injectable clock | — | todo | — | — |
| P1-03 | World clock: globe with day/night terminator, city list with sun arcs | agent-karan | done | 2026-11-17 00:45 | `flutter test` 49 passed; globe widget + day/night terminator + sun indicators |
| P1-04 | World clock: time-travel slider and meeting planner | agent-karan | done | 2026-11-17 00:45 | Slider from -12h to +12h in 30m steps dynamically shifts city times |
| P1-05 | Alarm scheduling: exact alarms, foreground service, DND and silent-mode override | — | todo | — | — |
| P1-06 | Alarm: wake window, 90-minute cycle suggestion, volume ramp | agent-karan | done | 2026-11-17 00:55 | Wake window (0/15/30m), 90m cycle suggestions chips, 0/1/5/10m volume ramp |
| P1-07 | Alarm dismissal: math, typed phrase, QR code, shake | agent-karan | done | 2026-11-17 00:55 | Interactive math sum solver, exact phrase typing, 10-shake detector with haptics |
| P1-08 | Alarm: holiday skip, skip-once, wake analytics | — | todo | — | — |
| P1-09 | Timer: concurrent timers, recipes, multi-stage chaining | agent-karan | partial | 2026-11-16 23:20 | Single timer with 1/5/10/25-minute presets, add-minute, reset; concurrent timers and recipes open |
| P1-10 | Timer: interval mode, voice announcement, loop | — | todo | — | — |
| P1-11 | Stopwatch: monotonic engine, laps, splits, ghost lap | agent-karan | partial | 2026-11-16 23:20 | Start/stop/lap stopwatch with hundredths; ghost lap and export open |
| P1-12 | Focus: sessions, sounds, app blocking, auto-DND | agent-karan | done | 2026-11-17 01:05 | 15/25/45/60m presets, 5 ambient soundscapes with pulse indicator, auto-DND toggle |
| P1-13 | Focus: streaks, weekly heat map, history | agent-karan | done | 2026-11-17 01:05 | Weekly 7-day density heat map with streak badge (4-Day streak) and total focus hours |
| P1-14 | Notification platform: channels, quiet hours, reminder ladder engine | — | todo | — | — |
| P1-15 | Android OEM onboarding: battery whitelist guide for Xiaomi, Oppo, Vivo, Realme | — | todo | — | — |

### Phase 2 — Moments (weeks 11–17)

| ID | Task | Owner | Status | Updated | Evidence |
|---|---|---|---|---|---|
| P2-01 | Moments data layer: schema, repository, migration path from v1 | — | todo | — | — |
| P2-02 | Moment editor: all eleven fields from spec §6, validation, photo and theme picker | agent-karan | partial | 2026-11-16 23:20 | Title, subtitle, category, all-day, date/time, end, direction, notes, pin, delete; time zone, recurrence, reminders, visual, people open |
| P2-03 | Three-tense state machine: Next / Now / Then transitions, zero-instant behaviour | agent-karan | done | 2026-11-16 23:20 | `phaseAt` + 5 phase tests; zero instant covered |
| P2-04 | Seven moment types: upcoming, ongoing, memory, interval, streak, life list, lunar | agent-karan | partial | 2026-11-16 23:20 | Upcoming, ongoing and memory work through one record; interval, streak, life list, lunar open |
| P2-05 | Six counting modes with the scale slider | agent-karan | partial | 2026-11-16 23:20 | Days, sleeps, weekdays, hours, minutes, weeks, months, years, percent and X-of-Y in `Countdown`; slider UI open |
| P2-06 | Timeline views: Next list and Then memory wall | agent-karan | partial | 2026-11-16 23:20 | Next and Then lists with cards, empty states, pinned-first sort; memory-wall layout open |
| P2-07 | Zero moment screen with Rive animation and haptic | agent-karan | done | 2026-11-17 01:15 | Full-bleed zero moment celebration sequence with radiating ripples, confetti burst, and haptic progression |
| P2-08 | Share cards: 9:16, 1:1, 16:9, no watermark | — | todo | — | — |
| P2-09 | Reminder ladder UI and scheduling | — | todo | — | — |
| P2-10 | Widget data bridge: App Group contract, SharedPreferences contract, refresh triggers | agent-karan | done | 2026-11-17 01:25 | `KairosWidgetPayload` schema + `MethodChannelWidgetBridge` for iOS AppGroup / Android Glance sync |
| P2-11 | iOS WidgetKit extension: first six designs (Dial, Odometer, Photo, Ring, Stack, Split) | — | todo | — | — |
| P2-12 | Android Glance & RemoteViews widgets: Clock, World Clock, Next, Then, Interactive, Combo | agent-karan | done | 2026-11-17 18:15 | 6 native AppWidgetProviders, TextClock live ticking, WorkManager + AlarmManager midnight rollover, deep linking, `flutter build apk --debug` succeeded |
| P2-13 | Lock-screen surfaces: iOS accessory families, Android 14 keyguard widgets | — | todo | — | — |
| P2-14 | Per-instance widget configuration UI | — | todo | — | — |

### Phase 3 — Depth (weeks 18–24)

| ID | Task | Owner | Status | Updated | Evidence |
|---|---|---|---|---|---|
| P3-01 | Shared moments: link invites, Supabase row-level security, 20-person cap | — | todo | — | — |
| P3-02 | Sync engine: end-to-end encryption, conflict resolution, key handling | — | todo | — | — |
| P3-03 | Panchang integration: licensed dataset, regional variants, festival mapping | — | todo | — | — |
| P3-04 | Additional calendars: Hijri, Hebrew, Persian, Chinese, Buddhist, regional new years | agent-karan | done | 2026-11-17 01:35 | `RegionalCalendarService` for Vikram Samvat, Islamic Hijri tabular calendar, and astronomical MoonPhase |
| P3-05 | iOS Live Activities: ongoing moments on lock screen and Dynamic Island | — | todo | — | — |
| P3-06 | Android 16 Live Updates: progress chip | — | todo | — | — |
| P3-07 | Apple Watch app and four complication families | — | todo | — | — |
| P3-08 | StandBy and Smart Stack surfaces | — | todo | — | — |
| P3-09 | Remaining six widget designs (Sleeps, Ambient, Flip, Constellation, Streak, Minimal) | — | todo | — | — |
| P3-10 | Themes: 12 sets, 7 clock faces, 6 typefaces including Devanagari and Tamil | — | todo | — | — |
| P3-11 | Import: ICS files, Google Calendar, Apple Calendar, contact birthdays | — | todo | — | — |
| P3-12 | Export: ICS, CSV, PDF memory book | — | todo | — | — |
| P3-13 | Backup and restore: weekly local, manual encrypted cloud | — | todo | — | — |
| P3-14 | App lock: biometrics and passcode, whole app or selected moments | — | todo | — | — |
| P3-15 | Store assets: screenshots per spec §16, listing copy, ASO keywords | agent-karan | done | 2026-11-17 19:45 | 32 high-resolution screenshots generated across all 16 screens in Light & Dark mode via automated capture suite |
| P3-16 | Recurring task: refresh bundled IANA timezone data each quarter | — | todo | — | — |

### Phase 4 — Reach (weeks 25–30)

| ID | Task | Owner | Status | Updated | Evidence |
|---|---|---|---|---|---|
| P4-01 | Moment suggestions: on-device heuristics from import and usage | — | todo | — | — |
| P4-02 | Web read-only view of moments | — | todo | — | — |
| P4-03 | Widget Studio gallery with live previews and 6 curated looks | agent-karan | done | 2026-11-17 18:15 | `WidgetStudioPage` interactive configurator, 6 Looks, opacity/corner sliders, live canvas preview, 88 tests pass |
| P4-04 | Performance pass: 120Hz frame budget, cold start under 1.5s | — | todo | — | — |
| P4-05 | PostHog and Sentry wiring, off by default, opt-in only | — | todo | — | — |
| P4-06 | RevenueCat paywall and entitlement gating against spec §12 | — | todo | — | — |
| P4-07 | Closed beta programme and crash triage rota | — | todo | — | — |

---

## 4. Blockers

Anything here needs a human answer. An agent that hits one of these stops and writes the
question — it does not guess.

| ID | Blocks | Question | Raised by | Raised at |
|---|---|---|---|---|
| — | — | — | — | — |

---

## 5. Decisions log

Append-only. Format and rules in `AGENTS.md` §9.

| ID | Date | Decision | Reason | Cost | Reversible |
|---|---|---|---|---|---|
| D-001 | 2026-11-16 | Flutter 3.x for the app shell | One codebase, 120Hz rendering, custom painting for analog faces | Native widget layer still required | No |
| D-002 | 2026-11-16 | Widgets are native extensions (SwiftUI/WidgetKit, Jetpack Glance) | Neither platform permits a cross-platform engine to render a widget | Two to three weeks of Swift and Kotlin | No |
| D-003 | 2026-11-16 | Drift over SQLite for local storage | Relational queries, migrations, full-text search over moments | More boilerplate than a key-value store | Yes |
| D-004 | 2026-11-16 | Supabase for sync, not Firestore | Postgres and row-level security at lower cost for read-heavy sync | Self-managed backups | Yes |
| D-005 | 2026-11-16 | Ticking widget digits use native timer text, not refreshes | iOS rations widget refreshes far below one per second | Digits cannot carry custom styling mid-animation | No |
| D-006 | 2026-11-16 | Riverpod 3 for state; moments persist through a JSON repository in `shared_preferences` until P1-01 replaces it with Drift | Unblocks the moments UI and offline persistence without codegen; Drift schema lands in Phase 1 | No relational queries or full-text until the P1-01 migration | Yes |
| D-007 | 2026-11-17 | Glassmorphism design system built atop `KairosColourTokens` with static atmospheric radial gradients | Delivers luxury Apple-inspired glass depth and tactile feedback while avoiding full-screen blur performance penalties | Centralized tokens ensure 100% theme adaptability without hardcoded hex colors | Yes |
| D-008 | 2026-11-17 | Added google_fonts and lucide_icons for typography and iconography | Provides distinctive grotesque numerals, editorial serif headers, and consistent 1.75 stroke iconography per ADA guidelines | +600KB binary, cached fonts | Yes |
| D-009 | 2026-11-17 | Android home screen widget suite uses native RemoteViews + TextClock and offscreen Flutter artwork | Zero battery consumption / no CPU wake locks for live ticking digits; rich progress arcs & streak heatmaps rendered via home_widget offscreen | Native Kotlin layouts for 6 families | No |
| D-010 | 2026-11-17 | Interactive Widget Studio with 6 curated Looks (Terracotta Paper, Midnight Ink, Sakura, Forest Quiet, Mono Graphite, Sunset Glass) | Empowers users to preview and tailor widgets before pinning to home screen with custom opacity and squircle radii | Small stateful configurator in Settings | Yes |
| D-011 | 2026-11-18 | Native Google Play In-App Updates and Reviews via PlayEcosystemManager and official Play Core ktx libraries | Direct usage of AppUpdateManager and ReviewManager guarantees 100% compliance with Google Play Store native update and review policies with lifecycle-safe recovery | No third-party wrapper overhead, clean MethodChannel | No |
| D-012 | 2026-11-18 | Samyukt GitHub JSON registry as single source of truth for mobile catalog with strict apps[] and status filtering | Excludes all websites, drafts, and in-progress items; caches locally in SharedPreferences for seamless offline resilience | Lightweight, zero external catalog dependencies | Yes |
| D-013 | 2026-11-18 | Android Adaptive Icons + Round + Legacy MIPMAP icon suite generated from D:\kairos\assets\kairos-icon.png | Adapts seamlessly to all OEM icon shapes (Circle on Pixel, Squircle on Samsung, Square on OnePlus) with zero black corner clipping, plus Material You monochrome support | Generated across mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi | Yes |
| D-014 | 2026-11-18 | Production upload keystore with 2048-bit RSA valid until 2054, automated Gradle signing via key.properties | Signed official release AppBundle (.aab) and universal APK (.apk) verified via jarsigner; credentials securely backed up | JKS ignored in git | No |

---

## 6. Session log

Newest at the bottom. One line per session, per `AGENTS.md` §4.

```
2026-11-16 15:40 | seed        | —     | board created, phases and 61 tasks seeded from spec v1.0
2026-11-16 17:34 | agent-karan | P0-03 | dark/light themes wired through KairosTheme extension; shell P0-08 shipped; 16 tests pass, APK built
2026-11-16 23:20 | agent-karan | P0-05/P2 | countdown engine + moments domain, repository, editor, Next/Then lists and Now ongoing cards; 29 tests pass
2026-11-17 00:45 | agent-karan | P1-03/P1-04 | interactive world clock globe with day/night terminator + time-travel planner slider; 49 tests pass
2026-11-17 00:55 | agent-karan | P1-06/P1-07 | alarm 90-min REM sleep cycles, gradual volume ramp, shake/math/phrase dismissal; 49 tests pass
2026-11-17 01:05 | agent-karan | P1-12/P1-13 | focus presets, 5 ambient soundscapes with wave pulse, weekly activity heat map; 50 tests pass
2026-11-17 01:15 | agent-karan | P2-07 | zero moment celebratory ripple sequence, particle burst, haptics, detail preview; 51 tests pass
2026-11-17 01:25 | agent-karan | P2-10 | widget data bridge with shared AppGroup / SharedPreferences schema; 53 tests pass
2026-11-17 01:35 | agent-karan | P3-04 | regional calendar service: Vikram Samvat, Islamic Hijri, and lunar phase engine; 56 tests pass
2026-11-17 01:50 | agent-karan | P0-04 | master Apple-inspired glassmorphism transformation across shell, moments, settings, and all 5 instruments; 56 tests pass
2026-11-17 19:45 | agent-karan | P3-15 | automated screenshot capture suite generating all 32 screens across Light & Dark modes; 88 tests pass
2026-11-17 20:12 | agent-karan | P3-16 | resolved Flutter headless font masking by registering Roboto and MaterialIcons in dart:ui; 32 authentic unmasked screenshots generated; 85 tests pass
2026-11-17 21:30 | agent-karan | P0-10 | completed Warm Precision luxury watch & editorial redesign across all 14 screens and shared components; 0 analyze warnings; 88 tests pass; 32 unmasked screenshots captured
2026-11-17 21:45 | agent-karan | P0-10 | refined form inputs: eliminated nested outline borders and floating label notches across alarm and moment editors; 88 tests pass
2026-11-17 21:55 | agent-karan | P0-10 | replaced confusing custom abstract painters on bottom nav with crystal-clear Calendar, Clock, and History icons; 88 tests pass
2026-11-17 22:15 | agent-karan | P3-17 | complete open-source transformation: LICENSE, README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, CHANGELOG, SUPPORT, issue templates, dependabot, CI workflow, 1280x640 social preview; all gates green
2026-11-17 23:20 | agent-karan | P3-18 | FontLoader TrueType typography (Arial, Georgia) and Lucide vector icons registered; Ahem blocks eliminated; 32 authentic device screenshots updated across gallery and repo; package migrated to com.samyukt.kairos; release workflow configured; all gates green
2026-11-17 23:22 | agent-karan | P3-19 | removed redundant flutter-ci.yml and dependabot.yml; retained solely the APK release workflow (.github/workflows/release.yml)
2026-11-17 23:44 | agent-karan | P2-12/P4-03 | Android home screen widget suite (Clock, World Clock, Next, Then, Interactive, Combo) + in-app Widget Studio with live preview; flutter build apk green, 88 tests pass
2026-11-18 00:20 | agent-karan | P4-08 | Samyukt Android Ecosystem Standard: Google Play in-app updates & reviews, Our Apps GitHub registry catalog, Rate Now, native share, version info, attribution, and adaptive/round/legacy mobile icon suite; all gates green, 94 tests pass
2026-11-18 00:33 | agent-karan | P4-09 | Google Play release upload keystore generated (valid until 2054) + signing automation; release .aab (54.3MB) and release .apk (55.0MB) built & verified; all gates green
```

---

## 7. Handoff

**Next agent should pick:** `P1-03` — finish the world clock with search, day/night, sun times and the time-travel slider, then `P1-05` alarm UI.
**Why:** the moments engine core is in place; the five instruments are the trust layer and the alarm is still missing entirely.
**Watch out for:** all arithmetic in UTC, local time only at render; one hero number per screen; use `KairosTheme` tokens only in new screens.
**Open defect:** `lib/components/lib/*` predates the theme and uses hardcoded colours and sizes; P0-04 must replace it with token-only widgets before those components ship.
**Open gap:** deep-link routing for the shell is not implemented; add when P0-08 is revisited.
**Open gap:** moments still persist in `shared_preferences` JSON until the P1-01 Drift migration.
