# AGENTS.md — Kairos build operating system

This file is the standing instruction set for any AI agent (or human) working in this
repository. It is stable. Read it once per session, fully, before touching anything.

The product itself is specified in `Kairos_Feature_Spec.pdf` at the repository root.
This file governs **how work is done**. It does not restate the spec.

The live state of the project — what is done, what is in progress, who is working on
what, and why decisions were made — lives in `STATUS.md`. Every session begins and ends
there.

---

## 1. Source of truth, in priority order

When two sources disagree, the higher one wins. Do not silently resolve a conflict;
record it (see §9).

1. `Kairos_Feature_Spec.pdf` — product scope, features, design language, constraints.
2. `STATUS.md` → **Decisions** section — agreed deviations from the spec, with rationale.
3. `STATUS.md` → **Task board** — what is in scope right now.
4. Existing code and tests — current behaviour.
5. Your own judgement — last, and only inside the boundaries of 1–4.

If the spec is silent on something and the decision is reversible, decide, implement,
and log it as a decision. If it is irreversible or user-visible in a way the spec
contradicts, stop and ask (§8).

---

## 2. Non-negotiable constraints

These are extracted from the spec and may never be traded away for speed. A change that
violates any of these is rejected regardless of how well it works.

**Product**
- No React Native, anywhere, for any reason.
- No advertising in any tier, ever. No ad SDK linked into the binary.
- No third-party analytics SDK. PostHog (self-hosted) only, and it must be off by default.
- No account required to use any feature. Sync is opt-in.
- Local-first: every feature works fully offline. Network failure is a normal state, not an error path.
- No marketing or re-engagement notifications. None exist in the product.
- No badge count on the app icon.
- No public profiles, feeds or follower graphs. Sharing is a private link only.

**Design**
- One hero number per screen. Two display-size numbers on one screen is a defect.
- Tabular figures for every digit that changes. A countdown must not reflow as it ticks.
- Tokens only. No hardcoded hex, no magic spacing numbers, no inline font sizes in widgets.
- 4pt spacing grid, 8pt layout grid.
- 44pt minimum touch target (48dp Android).
- 4.5:1 minimum contrast on every theme, in both modes.
- No state communicated by colour alone.
- Dark and light mode are both first-class. A screen shipped in one mode is not done.
- Reduce Motion, Reduce Transparency and text scaling to 310% must all be handled.

**Platform**
- iOS 17.0 minimum. Android 8.0 (API 26) minimum, Material You paths guarded at API 31+.
- Widgets are native: SwiftUI/WidgetKit on iOS, Jetpack Glance on Android. Flutter never
  renders inside a widget or a Live Activity; it only writes data across the bridge.
- All time arithmetic in UTC. Local time only at the render boundary.

---

## 3. The work loop

Every unit of work follows the same seven steps. Do not skip steps, do not reorder them,
do not batch several tasks into one pass.

**Step 1 — Orient.** Read `STATUS.md` in full. Read the spec section covering your task.
Check the **Decisions** log for anything that changes it. Check **Blockers**.

**Step 2 — Claim.** Pick exactly one task from the board. Set its `Status` to `active`,
put your agent name in `Owner`, and set `Updated` to the current UTC timestamp in
`YYYY-MM-DD HH:MM` form. Save `STATUS.md` before you write any code. This claim is what
prevents two agents from colliding.

**Step 3 — Specify.** Write the acceptance criteria for the task into its `Notes` cell
before implementing — 2 to 5 testable statements. If you cannot write them, the task is
too vague: split it on the board and claim the first half.

**Step 4 — Build.** Smallest correct change that satisfies the acceptance criteria.
Follow §6 conventions. Stay inside the task's file scope (§7).

**Step 5 — Verify.** Run the full gate set in §5. Not a subset. A task whose gate fails
is not done, no matter how good the code looks.

**Step 6 — Record.** Update `STATUS.md`: status to `done` or `review`, evidence column
filled with the actual command and its result, one line appended to the session log.

**Step 7 — Hand off.** Write the next task you would pick, in the handoff line. Then stop,
or claim the next task and repeat from Step 2.

---

## 4. The status board protocol

`STATUS.md` is the single shared memory of this project. Treat it as production data.

**Status values — use exactly these strings**

| Value | Meaning |
|---|---|
| `todo` | Specified, not started, free to claim |
| `active` | Claimed and being worked on right now |
| `review` | Implemented and gated, awaiting human review or device test |
| `blocked` | Cannot proceed; reason is in the Blockers section |
| `done` | Merged, gated, evidence recorded |

**Rules**

1. **Never delete a row.** Tasks are cancelled by setting `Status` to `blocked` with a
   reason, or by splitting into new rows. History is not editable.
2. **Never mark `done` without evidence.** The `Evidence` cell holds the literal command
   run and its result, e.g. `flutter test test/moments/tense_test.dart — 14 passed`.
   "Done" with an empty evidence cell is a protocol violation.
3. **One `active` task per agent.** Your name may appear on at most one `active` row.
4. **Never overwrite another agent's claim.** If a row is `active` and `Updated` is within
   the last 2 hours, it belongs to someone else. Pick a different task.
5. **Stale claim recovery.** If a row is `active` and `Updated` is more than 24 hours old,
   you may take it over — but first append a line to the session log saying you are doing
   so and why, then set `Owner` to yourself and `Updated` to now.
6. **Every write is timestamped.** `Updated` is UTC, `YYYY-MM-DD HH:MM`, no exceptions.
7. **New tasks go at the bottom of their phase.** Assign the next free ID in that phase
   (`P2-16` after `P2-15`). Never renumber.
8. **Keep it accurate before you log off.** A board that lies is worse than no board.
   If you ran out of time mid-task, leave it `active` with a note saying exactly where you
   stopped and what remains.

**Session log format** — append one line per session, newest at the bottom:

```
2026-11-16 15:40 | agent-claude | P1-03 | world clock globe + terminator shipped, gate green
```

---

## 5. Quality gates

Run all of these before marking any task `done`. Paste the real output into the
`Evidence` cell.

```bash
dart format --set-exit-if-changed .        # formatting is not a style debate
flutter analyze --fatal-infos              # zero warnings, zero infos
flutter test                               # all unit + widget tests
flutter test --coverage                    # changed files at or above 80%
dart run tool/check_tokens.dart            # no hex, no magic numbers outside tokens
dart run tool/check_strings.dart           # no user-facing string outside ARB files
flutter build apk --debug                  # Android compiles
flutter build ios --no-codesign            # iOS compiles (macOS runner only)
```

**Additional gate for anything touching a widget or a live surface**

```bash
# iOS widget extension
xcodebuild -scheme KairosWidgetExtension -destination 'generic/platform=iOS' build
# Android widget
./gradlew :app:assembleDebug && ./gradlew :app:lintDebug
```

**Additional gate for anything touching a moment, alarm or timer**

- A unit test proving the behaviour across a DST boundary.
- A unit test proving the behaviour at the exact zero instant.
- A widget test proving the screen renders with a 310% text scale.

If a gate cannot run in your environment (no macOS, no device), say so explicitly in the
`Evidence` cell and set the task to `review` rather than `done`.

---

## 6. Code conventions

**Structure** — feature-first, not layer-first.

```
lib/
  app/            # shell, router, theme wiring, bootstrap
  core/
    time/         # clock abstraction, tz service, formatters — all injectable
    design/       # tokens, theme extensions, typography
    widgets/      # shared presentational components
    data/         # database, repositories, migrations
    platform/     # widget bridge, notifications, permissions
  features/
    world_clock/  # each feature owns its own data/domain/presentation
    alarm/
    timer/
    stopwatch/
    focus/
    moments/
```

**Rules**

- `core/time` never calls `DateTime.now()` directly in testable code — take a `Clock`
  dependency so time is injectable. Every time-dependent test must control the clock.
- State via Riverpod 2. `Notifier` and `AsyncNotifier` only; no service locators, no
  globals, no `ProviderContainer` reads inside widgets.
- Models are immutable and `freezed`-generated. Mutations return new instances.
- Sealed classes for UI state: `Loading`, `Data`, `Empty`, `Failure`. Every screen renders
  all four. A screen without an empty state is not finished.
- Repositories return domain types, never Drift rows or raw JSON.
- No business logic in a widget. If a `build()` method contains a conditional that is not
  about layout, it belongs in a notifier.
- Every user-facing string lives in `lib/l10n/*.arb`. No exceptions, including debug labels
  that ship.
- Every numeric literal in a layout comes from a token. `16` is a bug; `Space.md` is correct.
- Wrap any `DateTime` crossing a layer boundary in an explicit UTC conversion and assert it
  in a test.

---

## 7. Scope discipline

- **One task, one branch, one PR.** Branch name `feat/<task-id>-<slug>`, e.g.
  `feat/p1-03-world-clock-globe`.
- **Do not refactor code outside your task.** If you find a defect elsewhere, add a row to
  the board; do not fix it in this PR.
- **Do not add a dependency without a decision entry.** Every package needs a one-line
  rationale in the Decisions log: what it does, what it costs, what it replaces.
- **Do not reformat files you did not otherwise change.** It buries the real diff.
- **No placeholder implementations.** No `// TODO: implement`, no stub returning fake data,
  no `throw UnimplementedError()` left in a task marked done. If it cannot be finished,
  it is not done — split the task.
- **Commit messages**: `type(scope): subject` in imperative mood, body explains why.
  Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`.

---

## 8. When to stop and ask

Stop, leave the task `active`, and write a clear question in the Blockers section when:

- The spec and the code genuinely contradict each other and both readings are plausible.
- The work needs a credential, signing certificate, store listing, or paid account.
- A database migration would destroy existing user data.
- The task needs more than three files changed outside its stated scope.
- A platform limitation makes an acceptance criterion impossible (e.g. a widget refresh
  cadence iOS will not grant).
- You would have to guess at a design decision that a designer would consider a real choice
  — a colour, a motion curve, a layout hierarchy — and the spec does not settle it.

Do not stop for: naming a private variable, choosing a file location inside the convention,
picking between two equivalent implementations, or anything reversible and internal.

---

## 9. Decisions log

Any choice that a future agent could reasonably reverse needs one entry in the
**Decisions** section of `STATUS.md`:

```
D-014 | 2026-11-16 | Bundled IANA tzdata instead of the platform time zone API
      | Reason: platform API returns stale data on Android 8-11 for recent DST rule changes
      | Cost: +1.2 MB APK, quarterly data refresh task (P3-16)
      | Reversible: yes
```

Rules: decisions are append-only, never edited. A decision that supersedes an earlier one
references it (`supersedes D-014`). If implementation drifts from the spec, the decision
entry is mandatory — a silent deviation is the single worst failure mode on this project.

---

## 10. Precision rules

These are the habits that separate a professional build from a plausible-looking one.

- **Reproduce before you fix.** For any bug, write the failing test first, watch it fail,
  then fix it. A fix without a regression test is not a fix.
- **State your assumption in the PR body** whenever you had to infer intent. One line.
- **Prefer deleting code to adding it.** The smallest diff that satisfies the criteria wins.
- **Test the boundary, not the middle.** Zero instants, DST transitions, leap days,
  29 February birthdays, timezone changes mid-timer, 310% text, empty lists, 10,000 items.
- **Never trust a green build you did not run.** Report the command, not the conclusion.
- **Numbers in the UI come from one formatter.** If two screens format a countdown
  differently, that is a defect in `core/time`, not in either screen.
- **If it takes more than one attempt to explain, the abstraction is wrong.** Rewrite it
  simpler rather than documenting the complexity.

---

## 11. Session ritual

**Start of session** — read `AGENTS.md`, read `STATUS.md` in full, note the current phase,
note any `blocked` rows that might be unblocked, then claim a task.

**End of session** — update `STATUS.md` (status, evidence, session log line, handoff line),
then report in exactly this shape:

```
Task:      P2-03 three-tense state machine
Status:    done | review | active | blocked
Changed:   4 files, +312 / -18
Gates:     analyze clean, 41 tests pass, format clean
Evidence:  flutter test test/moments/tense_test.dart — 14 passed
Next:      P2-05 six counting modes
Note:      DST edge case for date-only moments needs a product decision (see Blockers)
```

Six lines, always. No prose preamble. This is what makes the board trustworthy.

---

## 12. If you have just been handed this file

You are working on Kairos, a Flutter clock and moments app specified in
`Kairos_Feature_Spec.pdf` at the repository root.

Do this, in order:

1. Read this file completely.
2. Read `STATUS.md` completely.
3. Read the spec sections listed against the phase you are about to work in
   (spec §4 design language, §5 instruments, §6 moments, §7 widgets — read the one that
   covers your task, plus §2 and §3 always).
4. Claim one task per §3 Step 2, by editing `STATUS.md` first.
5. Work the loop to completion. Do not stop halfway and do not start a second task.
6. End with the six-line report in §11.

If `STATUS.md` is missing, create it from the template at the end of this file, seeding the
full task board, before doing anything else.
