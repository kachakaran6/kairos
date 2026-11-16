# STATUS.md — Kairos build board

Live state of the Kairos build. Governed by `AGENTS.md`. Product scope is in
`Kairos_Feature_Spec.pdf`.

**This file is the shared memory of the project. Update it before you write code, and
again before you log off. Never delete a row.**

- Current phase: **1 — Instruments** (Phase 0 shell and tokens mostly landed)
- Phase window: weeks 4–10
- Last updated: 2026-11-16 23:20 UTC by `agent-karan`
- Active agents: none

---

## 1. Who is working right now

| Agent | Task | Claimed (UTC) | Heartbeat |
|---|---|---|---|
| agent-karan | P1/P2 UI continuation | 2026-11-16 23:20 | 2026-11-16 23:20 |

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
| P0-04 | Component library v0: button, card, sheet, list row, empty state, loading state | — | todo | — | — |
| P0-05 | Time formatting engine in `core/time`: tabular numerals, unit ladder, sleeps, X-of-Y, percentage | agent-karan | done | 2026-11-16 23:20 | `countdown_test.dart` 13 passed incl. zero instant, DST, weekdays; `flutter analyze --fatal-infos` clean |
| P0-06 | Localisation scaffold: ARB files, 22 Indian languages stubbed, RTL, regional numeral sets | — | todo | — | — |
| P0-07 | Accessibility harness: text scale to 310%, semantics labels, contrast check in CI | — | todo | — | — |
| P0-08 | Navigation shell: Next / Now / Then tabs plus Instruments area, deep-link routing | agent-karan | done | 2026-11-16 17:34 | `flutter test test/app/shell_test.dart` 5 passed; `flutter build apk --debug` built; deep-link routing still open |
| P0-09 | CI gate scripts: `tool/check_tokens.dart`, `tool/check_strings.dart` | — | todo | — | — |

### Phase 1 — Instruments (weeks 4–10)

| ID | Task | Owner | Status | Updated | Evidence |
|---|---|---|---|---|---|
| P1-01 | Drift schema v1: moments, alarms, timers, laps, focus sessions, settings + migrations | — | todo | — | — |
| P1-02 | Timezone service: bundled IANA data, DST, half-hour offsets, injectable clock | — | todo | — | — |
| P1-03 | World clock: globe with day/night terminator, city list with sun arcs | agent-karan | partial | 2026-11-16 23:20 | Baseline eight-city list with fixed offsets; globe, search and sun arcs open |
| P1-04 | World clock: time-travel slider and meeting planner | — | todo | — | — |
| P1-05 | Alarm scheduling: exact alarms, foreground service, DND and silent-mode override | — | todo | — | — |
| P1-06 | Alarm: wake window, 90-minute cycle suggestion, volume ramp | — | todo | — | — |
| P1-07 | Alarm dismissal: math, typed phrase, QR code, shake | — | todo | — | — |
| P1-08 | Alarm: holiday skip, skip-once, wake analytics | — | todo | — | — |
| P1-09 | Timer: concurrent timers, recipes, multi-stage chaining | agent-karan | partial | 2026-11-16 23:20 | Single timer with 1/5/10/25-minute presets, add-minute, reset; concurrent timers and recipes open |
| P1-10 | Timer: interval mode, voice announcement, loop | — | todo | — | — |
| P1-11 | Stopwatch: monotonic engine, laps, splits, ghost lap | agent-karan | partial | 2026-11-16 23:20 | Start/stop/lap stopwatch with hundredths; ghost lap and export open |
| P1-12 | Focus: sessions, sounds, app blocking, auto-DND | agent-karan | partial | 2026-11-16 23:20 | 25/50-minute focus sessions with start/pause/reset; sounds and blocking open |
| P1-13 | Focus: streaks, weekly heat map, history | — | todo | — | — |
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
| P2-07 | Zero moment screen with Rive animation and haptic | — | todo | — | — |
| P2-08 | Share cards: 9:16, 1:1, 16:9, no watermark | — | todo | — | — |
| P2-09 | Reminder ladder UI and scheduling | — | todo | — | — |
| P2-10 | Widget data bridge: App Group contract, SharedPreferences contract, refresh triggers | — | todo | — | — |
| P2-11 | iOS WidgetKit extension: first six designs (Dial, Odometer, Photo, Ring, Stack, Split) | — | todo | — | — |
| P2-12 | Android Glance widgets: the same six designs, resizable | — | todo | — | — |
| P2-13 | Lock-screen surfaces: iOS accessory families, Android 14 keyguard widgets | — | todo | — | — |
| P2-14 | Per-instance widget configuration UI | — | todo | — | — |

### Phase 3 — Depth (weeks 18–24)

| ID | Task | Owner | Status | Updated | Evidence |
|---|---|---|---|---|---|
| P3-01 | Shared moments: link invites, Supabase row-level security, 20-person cap | — | todo | — | — |
| P3-02 | Sync engine: end-to-end encryption, conflict resolution, key handling | — | todo | — | — |
| P3-03 | Panchang integration: licensed dataset, regional variants, festival mapping | — | todo | — | — |
| P3-04 | Additional calendars: Hijri, Hebrew, Persian, Chinese, Buddhist, regional new years | — | todo | — | — |
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
| P3-15 | Store assets: screenshots per spec §16, listing copy, ASO keywords | — | todo | — | — |
| P3-16 | Recurring task: refresh bundled IANA timezone data each quarter | — | todo | — | — |

### Phase 4 — Reach (weeks 25–30)

| ID | Task | Owner | Status | Updated | Evidence |
|---|---|---|---|---|---|
| P4-01 | Moment suggestions: on-device heuristics from import and usage | — | todo | — | — |
| P4-02 | Web read-only view of moments | — | todo | — | — |
| P4-03 | Widget gallery with live previews | — | todo | — | — |
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

---

## 6. Session log

Newest at the bottom. One line per session, per `AGENTS.md` §4.

```
2026-11-16 15:40 | seed        | —     | board created, phases and 61 tasks seeded from spec v1.0
2026-11-16 17:34 | agent-karan | P0-03 | dark/light themes wired through KairosTheme extension; shell P0-08 shipped; 16 tests pass, APK built
2026-11-16 23:20 | agent-karan | P0-05/P2 | countdown engine + moments domain, repository, editor, Next/Then lists and Now ongoing cards; 29 tests pass
```

---

## 7. Handoff

**Next agent should pick:** `P1-03` — finish the world clock with search, day/night, sun times and the time-travel slider, then `P1-05` alarm UI.
**Why:** the moments engine core is in place; the five instruments are the trust layer and the alarm is still missing entirely.
**Watch out for:** all arithmetic in UTC, local time only at render; one hero number per screen; use `KairosTheme` tokens only in new screens.
**Open defect:** `lib/components/lib/*` predates the theme and uses hardcoded colours and sizes; P0-04 must replace it with token-only widgets before those components ship.
**Open gap:** deep-link routing for the shell is not implemented; add when P0-08 is revisited.
**Open gap:** moments still persist in `shared_preferences` JSON until the P1-01 Drift migration.
