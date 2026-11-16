# KAIROS — Implementation Specification

**Version 2.0 · 16 November 2026 · Derived from `Kairos_Feature_Spec.pdf` v1.0**

This document supersedes the PDF as the build reference for the *visual* layer. The PDF
says what the product is; this says exactly what to draw, in what order, to what
measurements, and what not to do.

It is written to be followed literally. Where a number is given, use that number. Where a
hex is given, use that hex. Nothing in here is a suggestion.

---

## Contents

1. [Diagnosis: why the current build looks wrong](#1-diagnosis-why-the-current-build-looks-wrong)
2. [The five laws](#2-the-five-laws)
3. [Design tokens](#3-design-tokens)
4. [Typography](#4-typography)
5. [Core components](#5-core-components)
6. [The app shell](#6-the-app-shell)
7. [Screen: Next](#7-screen-next)
8. [Screen: Now](#8-screen-now)
9. [Screen: Then](#9-screen-then)
10. [Screen: World clock](#10-screen-world-clock)
11. [Screen: Alarm](#11-screen-alarm)
12. [Screen: Timer](#12-screen-timer)
13. [Screen: Stopwatch](#13-screen-stopwatch)
14. [Screen: Focus](#14-screen-focus)
15. [Screen: Moment detail](#15-screen-moment-detail)
16. [Screen: Moment editor](#16-screen-moment-editor)
17. [Screen: The zero moment](#17-screen-the-zero-moment)
18. [Screen: Settings](#18-screen-settings)
19. [Home screen widgets](#19-home-screen-widgets)
20. [Motion and haptics](#20-motion-and-haptics)
21. [Data model and the time engine](#21-data-model-and-the-time-engine)
22. [Build order, step by step](#22-build-order-step-by-step)
23. [Acceptance criteria](#23-acceptance-criteria)
24. [Copy deck](#24-copy-deck)
25. [Anti-patterns: never do these](#25-anti-patterns-never-do-these)

---

## 1. Diagnosis: why the current build looks wrong

Four screens were reviewed: Next (empty), Now, Then (empty), World clock. The verdict is
not that the layout is broken. It is that **no design system was applied** — the app is
rendering Flutter's Material defaults with a dark surface colour dropped on top.

The defects, in order of how much damage they do:

| # | Defect | Where it shows | Why it reads as bad | The fix |
|---|---|---|---|---|
| 1 | The brand accent appears nowhere | Every screen | The icon is warm amber; the app is pure grey. There is no visual link between the store listing and the product | Amber `#E9A97B` on exactly one live element per screen |
| 2 | The Now screen has no clock | Now | This is a clock app whose home screen contains no time. The single most confusing thing in the build | A 64pt live time at the top of Now |
| 3 | Everything is one grey | All | Canvas, cards, rows, and labels are within a few percent of each other in luminance. Nothing separates | Five distinct surface steps, defined below |
| 4 | Typography is at default sizes | All | "Next" is ~17pt; the empty-state headline is ~28pt bold grey. The scale is inverted — a tab title should be the largest thing on screen | A fixed 10-step scale, §4 |
| 5 | Empty states are a giant grey glyph, centred, with dead space above | Next, Then | Reads as an error screen, not an invitation. Centred empty states look like placeholders | Left-aligned, accent-tinted, with a real button, §7.4 |
| 6 | The hourglass icon is used three times | Nav, empty states | It is the same glyph that was rejected for the app icon. It also means "waiting", not "ahead" or "behind" | A purpose-built 3-icon set, §5.8 |
| 7 | Bottom nav is Material's pill indicator | All | The grey lozenge is Android's default component. It is the clearest tell that this is a template | Custom 3-tab bar, no pill, §6.3 |
| 8 | Instrument rows are default list tiles | Now | Four identical 72pt rows with a chevron is the least informative way to present four different tools | A 2-up grid with live micro-values, §8.3 |
| 9 | World clock rows carry no information beyond the time | World clock | Day or night, the day of the week, and the offset from you are all missing — the three things a world clock is for | Day/night bar, date line, offset in words, §10 |
| 10 | The Alarm instrument is missing | Now | Four of five instruments are present | Five tiles, §8.3 |
| 11 | Cards have inconsistent radius and padding | All | 20pt radius on some, 12 on others, 16/20 padding varying | One radius scale, one padding scale, §3.4 |
| 12 | Nothing is aligned to a grid | All | Text baselines and card edges drift by 2–6pt between screens | 4pt grid, enforced in tokens, §3.3 |

The rebuild below addresses every row.

---

## 2. The five laws

Non-negotiable. A screen that breaks one of these is not finished, regardless of how it
otherwise looks.

**Law 1 — One hero.** Every screen has exactly one element at display size. On Next it is
the nearest countdown. On Now it is the current time. On Then it is the largest memory.
Two large elements on one screen is a defect.

**Law 2 — One accent.** Amber `#E9A97B` appears on the single live or interactive element
per screen, and nowhere else. Not on borders, not on section headers, not on two buttons.

**Law 3 — Depth by lightness, not shadow.** Dark interfaces separate surfaces by stepping
the background lightness, not by dropping shadows. Five steps only (§3.2). A shadow in dark
mode is a bug.

**Law 4 — Tabular or it jitters.** Any digit that changes on screen uses tabular figures.
A countdown that reflows as it ticks is the most obvious sign of an unfinished app.

**Law 5 — Nothing is centred that should be aligned.** Empty states, error states, and
body copy align left to the 20pt margin. Only the hero number centres.

---

## 3. Design tokens

Build these first. Every other screen consumes them. No screen may contain a raw hex, a
raw size, or a raw duration.

### 3.1 Colour — dark (default)

| Token | Hex | Use |
|---|---|---|
| `canvas` | `#0C0C0F` | App background, every screen |
| `surface1` | `#141418` | Cards, list rows, tiles |
| `surface2` | `#1B1B20` | Raised: sheets, menus, pinned cards |
| `surface3` | `#232329` | Inputs, pressed states, segmented control track |
| `hairline` | `#2A2A31` | 1px separators, card outlines |
| `ink1` | `#F5F2EE` | Headlines, hero numbers, active labels |
| `ink2` | `#A8A4A0` | Body copy, secondary values |
| `ink3` | `#6E6A67` | Captions, section headers, inactive tabs |
| `ink4` | `#46433F` | Disabled, dividers inside cards |
| `accent` | `#E9A97B` | The one live element per screen |
| `accentDeep` | `#B4552B` | Accent pressed, gradient end, progress track fill |
| `accentWash` | `#E9A97B` at 12% | Chips, tinted cards, selection |
| `night` | `#5A6B8C` | Night hours in world clock |
| `success` | `#7FB3A3` | Completed, on-track |
| `danger` | `#C2453C` | Destructive only |

### 3.2 Colour — light (parallel theme, not an inversion)

| Token | Hex |
|---|---|
| `canvas` | `#FBFAF7` |
| `surface1` | `#FFFFFF` |
| `surface2` | `#FFFFFF` |
| `surface3` | `#F1EEE8` |
| `hairline` | `#E4E0D8` |
| `ink1` | `#17171A` |
| `ink2` | `#5E5A55` |
| `ink3` | `#8A857E` |
| `ink4` | `#C4BFB6` |
| `accent` | `#A9552B` |
| `accentDeep` | `#8A4222` |
| `night` | `#4A5A7A` |

Light mode is a separate set of values, chosen to look right on paper-white. Never compute
it by inverting.

### 3.3 Spacing, radius, size

**Spacing** — every value is a multiple of 4. Never use 5, 6, 7, 9, 10, 11, 13, 14, 15.

| Token | Value | Use |
|---|---|---|
| `s1` | 4 | Icon-to-label |
| `s2` | 8 | Inside chips, between tight lines |
| `s3` | 12 | Between cards in a list |
| `s4` | 16 | Card inner padding |
| `s5` | 20 | **Screen horizontal margin** |
| `s6` | 24 | Card inner padding (large cards) |
| `s7` | 32 | Between sections |
| `s8` | 40 | Above a hero block |
| `s9` | 64 | Empty-state top offset from centre |

**Radius**

| Token | Value | Use |
|---|---|---|
| `rChip` | 10 | Chips, small tags |
| `rRow` | 16 | List rows, inputs, tiles |
| `rCard` | 20 | Moment cards, instrument tiles |
| `rHero` | 28 | The hero card, sheets |
| `rPill` | 999 | Buttons, segmented controls |
| `rWidget` | 24 | Home screen widget corners |

**Control heights** — `buttonLg` 52, `buttonMd` 44, `rowMin` 44 (never below), `tabBar` 64,
`navIcon` 24, `sectionGap` 32.

**Screen margin** — 20pt phone, 32pt tablet (`≥600dp`). Every screen. No exceptions.

### 3.4 Depth

Dark mode has no shadows. A card separates from the canvas by `surface1` plus a 1pt
`hairline` outline at 60% opacity. A raised element (sheet, menu) uses `surface2` and, if it
overlaps content, a 24pt blur backdrop at 8% black. That is the entire elevation system.

Light mode may use one shadow: `0 1px 2px rgba(0,0,0,0.06), 0 8px 24px rgba(0,0,0,0.05)` on
`surface1` cards. Nowhere else.

---

## 4. Typography

### 4.1 Family

Bundle **Inter** (variable, SIL Open Font License) as the single family for both platforms.
Do not depend on the system font: it renders differently on every OEM Android skin and the
layout will not hold. Bundle Inter with `fontFeatures: [FontFeature.tabularFigures()]`
enabled globally on numeric styles.

Add **Noto Sans Devanagari** and **Noto Sans Tamil** as fallbacks so a Hindi or Tamil
moment is set properly rather than substituted at render time.

### 4.2 The scale

Ten steps. Nothing between them.

| Token | Size / line height | Weight | Tracking | Colour | Use |
|---|---|---|---|---|---|
| `display` | 96 / 92 | 600 | −2.4 | ink1 | Hero countdown on a moment screen |
| `displaySm` | 64 / 64 | 600 | −1.6 | ink1 | Live time on Now, large memory |
| `title1` | 34 / 40 | 700 | −0.9 | ink1 | Screen title, scrolls with content |
| `title2` | 28 / 34 | 700 | −0.6 | ink1 | Empty-state headline, card hero |
| `headline` | 20 / 26 | 600 | −0.2 | ink1 | Card titles, sheet titles |
| `body` | 16 / 24 | 400 | 0 | ink2 | Paragraphs |
| `bodySm` | 14 / 20 | 400 | 0 | ink2 | Secondary lines, list subtitles |
| `label` | 13 / 18 | 700 | +0.6 | ink3 | **Section headers, uppercase** |
| `caption` | 12 / 16 | 500 | +0.2 | ink3 | Units, offsets, dates |
| `micro` | 10 / 14 | 600 | +0.4 | ink3 | Widget footnotes, tab labels |

### 4.3 Rules

- Section headers are `label`, **uppercase**, with `+0.6` tracking. "INSTRUMENTS", not
  "Instruments".
- Never put body copy in `ink3`. `ink3` is for labels and captions only; body is `ink2`.
- Numbers in `display`, `displaySm`, `title2` and `headline` always use tabular figures.
- One space before a unit, never a non-breaking join: `11 days`, `4 h 12 m`.
- Screen titles are `title1`, left-aligned at the 20pt margin, and they scroll away.
  They never sit in a fixed app bar.
- A collapsed title (after 24pt of scroll) is `headline` at 17pt, centred, with a `hairline`
  bottom border and a 12pt blur backdrop.

---

## 5. Core components

Build in this order. Every screen is assembled from these and nothing else.

### 5.1 `KairosSurface`

The base card. `surface1`, radius `rCard`, 1pt `hairline` outline, padding `s4`.
Never nest one inside another. Never put a shadow on it.

### 5.2 `SectionHeader`

```
[label] 13/18 700, +0.6 tracking, UPPERCASE, ink3
padding: 0 20, top 32, bottom 12
optional trailing action: 13/18 600, accent, e.g. "See all"
```

### 5.3 `HeroNumber`

The most important component in the app. Anatomy:

```
Row(baseline aligned):
  number    display or displaySm, ink1, tabular
  unit      20/26 600, ink3, offset +8 from the number, baseline aligned
```

Rules:
- The unit is never the same size as the number.
- The number animates with an odometer roll (each digit a `SlideTransition` inside a clipped
  box, 420ms spring, 20ms stagger left to right). It never fades, never cuts.
- When the number is 0–9, the box is fixed-width so the layout does not shift.
- Optional progress ring: 3pt stroke, `accent` on an `ink4` track, drawn outside the number
  at 120% of its width, starting at 12 o'clock.

### 5.4 `MomentCard` (compact)

Used in lists.

```
height 72
radius rCard
surface1, hairline
padding 16 horizontal
layout: [theme dot 8pt] 12 [title bodySm/600 ink1 + subtitle caption ink3] → [countdown right]
countdown: 20/26 600 tabular ink1, unit 12/16 ink3
```

### 5.5 `MomentCard` (hero)

Used once per screen at most.

```
height 300 (or 340 with photo)
radius rHero
background: theme gradient, or photo with a 40% black scrim from the bottom
padding 24
layout (bottom-anchored, left-aligned):
  label       13/18 700 uppercase, white 70%
  number      display, white
  unit        20/26 600, white 60%
  title       20/26 600, white
  date        12/16 500, white 55%
```

### 5.6 `InstrumentTile`

```
height 96
radius rCard
surface1 + hairline
padding 16
layout:
  icon 22, accent at 80% opacity, top-left
  name 15/20 600 ink1, below icon, +12
  micro-value 12/16 500 ink3, below name, +4
```

The micro-value is what makes this component good. It carries live state: the next alarm
time, whether a timer is running, today's focus minutes. A tile without one is a menu item,
not a tool.

### 5.7 `PrimaryButton`

```
height 52
radius rPill
background accent
label 15/18 700, colour #0C0C0F (canvas) — dark text on amber
padding 0 24
pressed: accentDeep, scale 0.98, 120ms
```

`SecondaryButton` — same geometry, transparent, 1pt `hairline` border, label `ink1`.

### 5.8 The icon set

Three custom glyphs replace the hourglass everywhere. All 24×24, 1.75pt stroke, round caps,
round joins, drawn as `CustomPainter` or an SVG path — not from an icon font, so they match
across platforms.

| Tab | Glyph | Reads as |
|---|---|---|
| Next | A circle with an arrow leaving its top-right, drawn open at the gap | Ahead, going forward |
| Now | Two concentric rings with a filled centre dot | Present, the pivot |
| Then | A circle with a short trail of two arcs behind it, fading | Behind, receding |

Inactive: `ink3`. Active: `accent`. Never filled, never two colours.

Instrument icons: world clock (a sphere with a meridian), alarm (a bell with a flat base),
timer (a ring with a single tick), stopwatch (a ring with a crown), focus (a ring with a
centre dot and two brackets). Same 1.75pt stroke.

---

## 6. The app shell

### 6.1 Frame

- `Scaffold` background `canvas`. No `AppBar`.
- Status bar transparent, icons light. Safe area respected.
- Screen margin `s5` = 20 everywhere.
- Vertical scroll on every tab root. Content starts 8pt below the safe area top.

### 6.2 Title behaviour

```
scroll offset 0–24     : title1 at 20pt margin, y = safeTop + 8
scroll offset > 24     : fade title1 out (0→1 over 24pt), fade the collapsed
                         title in, draw a hairline at safeTop + 52
```

The title row also carries a trailing `+` action (24pt, `ink1`) on Next, and a search glyph
on Then. Both are 44pt targets.

### 6.3 Bottom navigation

Replace `NavigationBar` entirely. Do not use the Material component.

```
height 64 + bottom safe area
background canvas, 1pt hairline on top
3 items, equal width, each a 44pt target
icon 24, label micro 10/14 600, gap 4
inactive: icon and label ink3
active:   icon and label accent, label ink1
transition: colour tween 200ms, icon scale 1.0 → 1.06 spring
```

No pill. No background highlight. No elevation. The colour change plus the scale is enough,
and it is what makes the bar read as designed rather than assembled.

### 6.4 Page transitions

Tab switches: no animation (instant), because tabs are siblings.
Push: shared-axis horizontal, 320ms, incoming from right at 0.06 parallax.
Sheet: slide up 320ms spring, backdrop fades to 8% black.
Zero moment: full-screen fade-through, 600ms, no slide.

---

## 7. Screen: Next

The screen the user opens most. It answers one question: how long until the next thing.

### 7.1 Structure, top to bottom

```
1. Title row          "Next"                    + button (24pt, ink1)
2. Hero card          nearest moment            300pt tall, rHero
3. Section header     "COMING UP"               only if 2+ more moments
4. Moment list        next 5 moments, compact cards, 12pt apart
5. Bottom padding     24
```

### 7.2 Hero card

The nearest moment is the hero. Full width minus the 20pt margins, 300pt tall.

- Background: the moment's theme gradient. Default theme "Midnight": `#141418` → `#0C0C0F`
  at 135°. If the moment has a photo, the photo with a bottom-up scrim
  (`rgba(0,0,0,0)` at 40% height → `rgba(0,0,0,0.72)` at 100%).
- Content bottom-anchored, 24pt padding, left-aligned.
- `label` uppercase: the category — "BIRTHDAY", "EXAM", "TRIP".
- `HeroNumber`: 11 with unit "days". At `display` 96pt. This is the largest thing in the app.
- Title: 20/26 600 white.
- Date: 12/16 500 white 55% — "Sun, 27 Nov · in 11 days".
- A 3pt progress ring is drawn around the hero number's baseline area only if the moment
  has a start date. Otherwise no ring.

### 7.3 Moment list

`MomentCard` compact, §5.4. Sorted ascending by target time. Pinned moments first.
Maximum 5 shown, then a `See all` text action in the section header.

### 7.4 Empty state — the exact fix

This is the screen that looked worst. Current: a 64pt grey hourglass centred in a void with
a 28pt grey headline under it. Replace it entirely.

```
Layout: left-aligned at the 20pt margin
Vertical: the block's top edge sits at 38% of the viewport height — not centred

  glyph       Next icon, 40pt, accent at 45% opacity, aligned left
  gap         s6 (24)
  headline    title2 28/34 700 ink1, left        "Nothing ahead yet"
  gap         s2 (8)
  body        body 16/24 ink2, left, max 2 lines
              "Add the day you are counting to. It will sit here,
               at the top of your day, until it happens."
  gap         s7 (32)
  button      PrimaryButton, full width minus margins, "Add a moment"
  gap         s3 (12)
  text action 14/20 600 ink2, left, "See how moments work"
```

Rules that make this read as designed:
- Nothing is horizontally centred.
- The glyph is accent-tinted, small, and top-left — an illustration, not an error icon.
- There is a real, filled primary button. An empty state without an action is a dead end.
- The headline is `title2` and the body is `body` — a clear two-step hierarchy, not two
  greys of the same size.
- No more than 38% of the viewport is empty above the block.

### 7.5 States

| State | Rendering |
|---|---|
| Loading | Three skeleton cards: `surface1`, rCard, 72pt, with a 1.2s shimmer from 4% to 9% white. Never a spinner. |
| Empty | §7.4 |
| Populated | §7.2 + §7.3 |
| Error (DB read failed) | Same geometry as empty, glyph replaced with a small warning, copy "Couldn't load your moments", action "Try again" |
| All moments past | Hero card shows the most recent memory instead, label "LAST ONE", with the count-up. Next never shows a void if the user has any data at all. |

---

## 8. Screen: Now

Currently a list of four menu rows. It is the app's home and it contains no time. Rebuild
it as the clock screen.

### 8.1 Structure

```
1. Title row            "Now"                                  settings glyph (24, ink3)
2. Live clock block     64pt time + date + a 1pt rule
3. Live activity card   only if a timer, stopwatch or focus session is running
4. Section header       "INSTRUMENTS"
5. Instrument grid      2 columns, 5 tiles, last spans both
6. Section header       "HAPPENING NOW"
7. Ongoing moments      compact cards with a progress bar
```

### 8.2 The live clock block

The single change that fixes this screen.

```
time       displaySm 64/64 600, tabular, ink1        "23:08"
seconds    24/26 600, ink3, baseline aligned, +6     "42"
date       bodySm 14/20, ink3, +8 below              "Sunday, 16 November"
rule       1pt hairline, full width, +20 below the date
```

The time ticks every second with no animation on the digits — a clock does not roll, it
changes. Only the seconds field updates; the hour and minute fields are static widgets so
the tree does not rebuild the whole line each second.

Respect the 12/24-hour setting and the regional numeral setting (Devanagari, Tamil, Bengali
digit sets) from settings.

### 8.3 Instrument grid

Two columns, 12pt gutter, 5 tiles:

| # | Tile | Icon | Micro-value |
|---|---|---|---|
| 1 | World clock | sphere | `London 17:38` — the first pinned city, or `5 cities` |
| 2 | Alarm | bell | `07:00` — the next alarm, or `No alarm` |
| 3 | Timer | ring + tick | `Running · 4:12` in accent if active, else `No timers` |
| 4 | Stopwatch | ring + crown | `00:00.00`, or the running time in accent |
| 5 | Focus | brackets | `42 min today` with a 3pt progress ring on the right |

Tile 5 spans both columns and is 96pt tall, matching the grid rhythm. When any instrument is
live, its micro-value turns `accent` and the tile's hairline becomes `accentWash`. That is
the only accent use on this screen apart from the clock's seconds.

### 8.4 Live activity card

When something is running, a card pins directly under the clock:

```
height 88, radius rCard, background accentWash, no hairline
layout: [instrument icon 20 accent] 12 [name 15/600 ink1 + elapsed 12/500 ink2] → [Stop 13/600 accent]
progress: 2pt bar along the bottom edge, accent on ink4
```

Only one live activity card at a time. If a timer and a focus session both run, the timer
wins and the focus session shows in its tile.

### 8.5 Happening now

Ongoing moments (trips, exam windows, sprints) as compact cards with a 2pt progress bar
under the title showing elapsed fraction. Empty state here is **inline, not a block**:

```
bodySm 14/20 ink3, left, 0 top margin, 8 bottom
"No moment in progress."
```

Never render a big empty state inside a section on a populated screen.

---

## 9. Screen: Then

The memory wall. This screen should feel warm — it holds the things people never want to
lose.

### 9.1 Structure

```
1. Title row        "Then"                        search glyph (24, ink3)
2. Hero memory      the pinned or most significant memory, 260pt, rHero
3. Section header   "MEMORIES"
4. Memory grid      2 columns, staggered, 12pt gutter
```

### 9.2 Memory card

```
width  (screen − 40 − 12) / 2
height 168 (varies by 16 for a staggered rhythm)
radius rCard
background: theme gradient or photo at 85% with a bottom scrim
padding 16, content bottom-anchored left
  number    28/34 700 tabular, white
  unit      13/18 600, white 60%
  label     13/18 500, white 85%, 2 lines max
  date      10/14 600, white 45%
```

Numbers count **up**: "1,284 days", "3 years", "47 weeks". Pick the unit that reads best —
days under 60, months under 24, years above.

### 9.3 Empty state

Same geometry as §7.4, with:

```
glyph      Then icon, 40pt, accent 45%
headline   "Nothing behind yet"
body       "Moments move here once they pass, and count up
            from then on. Add one that already happened."
button     "Add a past date"        (secondary, not primary)
```

The secondary button is deliberate: adding a past date is a rarer action than adding a
future one, so it does not get the accent fill.

---

## 10. Screen: World clock

The current build is a list of city names and times. It omits day/night, the date, and the
offset — the three things the screen exists for.

### 10.1 Structure

```
1. Nav row        back arrow 44pt + "World clock" headline, centred
2. Dial strip     horizontally scrolling analog dials, 96pt, for pinned cities
3. Search field   44pt, surface1, rRow, placeholder "Search a city or airport code"
4. City list      rows, 76pt, 8pt apart
5. Add button     "+ Add city" text action at the end of the list
```

### 10.2 The dial strip

Each dial is a 96pt `CustomPainter`:

```
outer ring     1.5pt, ink4
hour ticks     4 ticks at 12/3/6/9, 1.5pt, ink4 at 60%
hour hand      2.5pt, ink1, length 30% of radius
minute hand    1.5pt, ink2, length 42% of radius
centre dot     3pt, accent
day/night arc  2pt along the outer ring: accent for daylight hours, night for the rest,
               computed from the city's sunrise and sunset
label below    city name 12/16 500 ink2, centred
```

The day/night arc is what makes this component worth building. It turns a clock into a
world clock.

### 10.3 City row

```
height 76, radius rRow, surface1, hairline
padding 16
layout:
  [day/night bar] 3pt wide, 40pt tall, radius 2, at the left inner edge
       daylight  accent
       night     night
       dawn/dusk  a vertical gradient accent → night
  16
  city name      17/20 600 ink1
  date + day     12/16 500 ink3, +4        "Mon, 17 Nov"
  → right
  time           28/34 600 tabular, ink1 (ink2 if the city is at night)
  offset         12/16 500 ink3, right     "5:30 ahead of you"
```

Offsets are always expressed relative to the user, in words: `same as you`, `5:30 ahead of
you`, `10:30 behind you`. The raw `UTC+05:30` string is available only in the city's detail
sheet.

### 10.4 Behaviours

- Cities sort by offset by default; the user can pin, reorder, or sort by name.
- Long-press a row opens a sheet: set as home, remove, see sunrise and sunset.
- Tapping a row opens the full-screen dial for that city: 280pt dial, the date, the sun
  arc with rise and set times, and the meeting-planner overlap bands.
- The meeting planner is a horizontal 24-hour band per selected city, shaded `accentWash`
  inside 09:00–18:00, with the best common hour outlined in `accent`.

---

## 11. Screen: Alarm

```
1. Nav row        back + "Alarm" + "+" action
2. Next alarm     hero block: the time at displaySm, "in 7 h 52 m" in accent, the
                  wake window drawn as a 6pt band under the time
3. Section header "ALARMS"
4. Alarm rows     88pt: time 34/40 600 tabular left, label bodySm ink2 under it,
                  right a 51×31 switch; disabled rows drop to ink3
5. Section header "SLEEP"
6. Bedtime block  suggested bedtime, average sleep, a 7-day bar chart of hours slept
```

The wake window is drawn as a horizontal band: a 6pt `accentWash` track from the window
start to end, with a 2pt `accent` marker at the set time. That single element explains the
feature better than any label.

Alarm ring screen: full-screen `canvas`, the time at `display` 96pt centred, the label
below, and a single "Stop" pill at the bottom with a 96pt swipe-up target. Dismissal by
math/QR/phrase opens as a sheet over it.

---

## 12. Screen: Timer

```
1. Nav row        back + "Timer" + history glyph
2. Dial           a 260pt ring, 6pt stroke, accent on ink4, with the remaining time
                  at displaySm centred inside, and the timer name below in caption
3. Controls       three 72pt circular buttons: reset (44pt glyph), start/pause (72pt,
                  accent fill, canvas-coloured glyph), +1 min
4. Presets        a horizontal row of chips: Chai 4:00, Rice 12:00, Pasta 9:00, Eggs 6:00
5. Section header "SAVED TIMERS"
6. Timer rows     name, duration, a play glyph
```

The ring is the hero. It depletes counter-clockwise from 12 o'clock and the remaining time
never moves position. Multi-stage recipes show stage dots under the ring: `● ● ○ ○`.

Running state: the nav row is replaced by a compact strip showing the name and a pause
glyph, and the whole screen scrolls to keep the ring centred.

---

## 13. Screen: Stopwatch

```
1. Nav row        back + "Stopwatch" + share glyph
2. Time           display 96/92 tabular, ink1, centred, format MM:SS.hh
3. Lap delta      a small line under the time: "+0.42" in danger or "−0.18" in success,
                  against the best lap
4. Controls       reset (44) · start/lap (72, accent) · lap list glyph (44)
5. Lap list       rows 56pt: "Lap 7" ink2 · split ink1 tabular · total ink3 tabular;
                  best lap marked with a 2pt accent bar on the left, worst with danger
```

The lap delta under the time is what separates this from every free stopwatch: it tells you
whether the lap you just ran was better, while you are still breathing hard.

---

## 14. Screen: Focus

```
1. Nav row        back + "Focus" + settings glyph
2. Ring           240pt, 8pt stroke, accent on ink4, remaining time at displaySm centred
3. Mode chips     Pomodoro · Deep work · Custom
4. Sound row      a 44pt row: sound name, a small waveform, and a play glyph
5. Stats block    three columns: today, streak, best day — each a number at 28/34 700
                  with a caption under it
6. Heat map       7 columns × 6 rows of 12pt squares, ink4 empty, accentWash partial,
                  accent full
```

Blocking status appears as a chip under the ring: "Blocking 6 apps" in `accentWash`.

---

## 15. Screen: Moment detail

Opened by tapping any moment. The emotional centre of the app.

```
1. Background      the moment's theme gradient or photo, full bleed, scrimmed 60% at the base
2. Top row         back (44) · share (24) · edit (24), all white at 80%
3. Hero block      centred vertically at 42% of the screen:
     label         uppercase, white 65%          "BIRTHDAY"
     number        display 96, white
     unit          20/26 600, white 60%
     title         title2 28/34 700, white
     date          14/20 500, white 55%          "Sunday, 27 November 2026"
4. Progress ring   if the moment has a start: 3pt arc around the hero block, accent
5. Bottom card     surface2, rHero, inset 20, sitting above the safe area:
     three columns, each a number + caption:
        "214" days together · "151" to go · "58%" complete
6. Reminder row    "Reminds you 7 days before" + a chevron
7. Notes           body ink2, collapsed to 3 lines with a "More" action
```

The three-column stat card is what turns a countdown into a record. It is also the only
place in the app where three numbers appear together — and they are all `headline` size,
not display, so Law 1 holds.

---

## 16. Screen: Moment editor

A full-screen sheet, `surface2`, rHero top corners, presented with a 320ms spring.

```
1. Header       "New moment" headline, Cancel (ink2) left, Save (accent, disabled until
                valid) right
2. Title field  a large borderless input: 28/34 700, placeholder in ink3,
                "What are you counting to?"
3. Date picker  a 320pt inline calendar, accent for today, accentWash for the selection
4. Time         a row: date, time, and a time-zone chip
5. Direction    segmented control: Count down · Count up · Both
6. Recurrence   a row opening a sheet: Never · Yearly · Monthly · Weekly · Custom · Lunar
7. Category     a horizontal chip row with 8 icons
8. Theme        a horizontal strip of 12 theme swatches, 56pt circles, selected one gets
                a 2pt accent ring with a 3pt gap
9. Photo        "Add a photo" row, 56pt thumbnail if set
10. Reminders   a row: "7 days before, 1 day before, on the day" + chevron
11. People      "Share with someone" row
12. Delete      only in edit mode, danger, at the bottom
```

Validation: Save is disabled until a title and a date exist. Date in the past with direction
"Count down" shows an inline error under the date: "That date has already passed — count up
instead?" with a one-tap fix.

---

## 17. Screen: The zero moment

When a countdown reaches zero. This is the app's signature thirty seconds and the screen
that gets screenshotted.

```
0.0s    the app takes the whole screen, canvas colour, everything else fades out over 200ms
0.2s    the hero number rolls to 00 and dissolves: scale 1.0 → 1.4, opacity → 0, 500ms
0.4s    the title scales up from 28 to 40 and settles at the centre
0.6s    the celebration animation plays — a Rive file chosen by category
0.6s    one haptic: .heavyImpact then a 40ms delay then .mediumImpact
1.2s    the label under the title fades in: "It's here."
2.0s    two buttons fade up: "Share" (primary) and "Keep counting" (secondary)
```

After dismissal, the moment flips to counting up with no user action. If the user does
nothing for 20 seconds, the screen dims and returns to the app with the moment now in Then.

Category animations: birthday → confetti; exam → a burst of lines; travel → a plane path;
memorial → no animation at all, just a slow fade and a single line of text. The memorial
case must be handled separately and quietly — this is the most important detail in the
whole feature.

---

## 18. Screen: Settings

```
Sections: Appearance · Time and date · Notifications · Data · About
Rows 56pt, icon 20 ink3, label 15/600 ink1, value 15/400 ink3 right, chevron optional
Theme row opens a sheet with a 3×4 grid of theme swatches, live preview behind it
```

Never a wall of switches. Every toggle has a one-line explanation under its label in
`bodySm` `ink3`.

---

## 19. Home screen widgets

Widgets are native. Flutter writes data; SwiftUI and Glance draw. See `AGENTS.md` §2.

### 19.1 Shared contract

The bridge writes a JSON blob to shared storage (App Group on iOS, SharedPreferences on
Android) on every moment change:

```json
{
  "v": 1,
  "generatedAt": "2026-11-16T17:30:00Z",
  "moments": [
    { "id": "m_01", "title": "Ananya's wedding", "category": "wedding",
      "target": "2026-11-27T09:30:00+05:30", "direction": "down",
      "theme": "midnight", "accent": "#E9A97B", "photoPath": "…",
      "countMode": "days", "pinned": true }
  ],
  "instruments": { "nextAlarm": "07:00", "timerRunning": false }
}
```

The widget renders the ticking digits with the platform's own timer text — `Text(timerInterval:)`
on iOS, `Chronometer` on Android — so no refresh is needed for the number to advance.

### 19.2 The twelve designs

| # | Design | Layout | Sizes |
|---|---|---|---|
| 1 | Dial | 96pt analog dial, countdown as a 2pt progress arc, city or title under | 2×2, 4×2 |
| 2 | Odometer | The number at 56pt tabular, unit under, nothing else | 2×2, 4×2, 4×4 |
| 3 | Photo | Full-bleed photo, 40% bottom scrim, number 32pt, title 12pt | 4×2, 4×4 |
| 4 | Ring | 3pt progress ring with the percentage centred, title under | 2×2 |
| 5 | Stack | Three compact rows, nearest first, each with a 6pt theme dot | 4×2, 4×4 |
| 6 | Split | Two halves, two cities or two moments, a 1pt hairline between | 4×2 |
| 7 | Sleeps | The word "sleeps" at 20pt above a 44pt number | 2×2, 4×2 |
| 8 | Ambient | A time-of-day gradient with the number at 40pt, no other chrome | 4×2, 4×4 |
| 9 | Flip | Flip-clock digits on a `surface3` plate, 3pt gap between cards | 2×2, 4×2 |
| 10 | Constellation | Moments as dots along a horizontal line, now marked in accent | 4×2 |
| 11 | Streak | A 7×4 day grid, lit days accent, the count above | 2×2 |
| 12 | Minimal | Label 10pt `ink3` over number 28pt `ink1`, 16pt padding | 2×2 |

### 19.3 Widget rules

- Padding is always 16, except Minimal at 16 and Photo at 0.
- Corner radius follows the platform: the system masks it. Never draw your own corners.
- Background: `#0C0C0F` at 100%. Never transparent — widgets over wallpaper look muddy.
- One accent per widget, matching the moment's theme.
- Lock screen families use `micro` type only and a single line.
- No widget shows more than three numbers.

---

## 20. Motion and haptics

### 20.1 Durations and curves

| Token | Value | Use |
|---|---|---|
| `quick` | 120ms, `easeOutCubic` | Pressed states, colour tweens |
| `standard` | 220ms, `easeInOutCubic` | Expansions, fades |
| `spring` | mass 1, stiffness 220, damping 26 | Cards, sheets, odometer |
| `page` | 320ms, shared-axis | Pushes |
| `celebrate` | 500ms, `easeOutQuart` | The zero moment |

Rules: nothing linear except progress bars. No bounce beyond 4% overshoot. No animation on
first paint — content appears settled, then animates only in response to input.

### 20.2 Haptics

| Event | Pattern |
|---|---|
| Tab change | `selectionClick` |
| Odometer roll | `lightImpact` |
| Button press | `lightImpact` |
| Timer complete | `mediumImpact` × 2, 80ms apart |
| Alarm ring | a rising pattern, 6 pulses over 3s |
| Zero moment | `heavyImpact` then `mediumImpact` |
| Error | `vibrate` 40ms |

Respect the system haptics setting. Never fire haptics on scroll.

---

## 21. Data model and the time engine

```dart
enum MomentDirection { down, up, both }
enum CountMode { days, sleeps, hours, weeks, months, years, percent, fraction }

class Moment {
  final String id;
  final String title;
  final DateTime? startUtc;     // null for a point-in-time moment
  final DateTime targetUtc;     // always UTC
  final String tzId;            // IANA, for rendering
  final MomentDirection direction;
  final CountMode countMode;
  final Recurrence recurrence;  // none | yearly | monthly | weekly | custom | lunar
  final String category;
  final String theme;
  final String? photoPath;
  final bool pinned;
  final List<ReminderRule> reminders;
  final String? notes;
}
```

Rules:

- Every `DateTime` crossing a layer boundary is UTC. Convert to local only in the
  presentation layer, using the moment's `tzId`, never the device zone.
- `Clock` is injected. No `DateTime.now()` inside a notifier or a widget. Every
  time-dependent test controls the clock explicitly.
- The tense is derived, never stored:

```dart
Tense tenseAt(DateTime nowUtc) {
  if (nowUtc.isBefore(targetUtc)) return Tense.next;
  if (startUtc != null && nowUtc.isBefore(startUtc!)) return Tense.next;
  if (startUtc != null && nowUtc.isAfter(startUtc!)) {
    // ongoing until targetUtc
  }
  return nowUtc.isAfter(targetUtc) ? Tense.then : Tense.now;
}
```

- Countdown formatting lives in one place: `core/time/CountdownFormatter`. No screen
  formats a duration itself. If two screens show the same moment differently, that is a
  defect in the formatter.
- DST, leap day, and half-hour offsets each need a unit test. Non-negotiable.

---

## 22. Build order, step by step

Do these in order. Each step ends with a working, visible result. Do not start step *n+1*
until step *n* passes its acceptance criteria.

### Phase A — Foundation (steps 1–8)

- [ ] **1.** Create the Flutter project. Bundle Inter, Noto Devanagari, Noto Tamil. Set
      `useMaterial3: true` but override every visual token.
- [ ] **2.** Write `lib/core/design/tokens.dart`: colour, spacing, radius, duration, as
      immutable classes. No widget may import a raw hex after this step.
- [ ] **3.** Write `KairosTheme.dark` and `KairosTheme.light` as `ThemeData` built entirely
      from tokens. Register both. Add a debug toggle to switch.
- [ ] **4.** Write the ten `TextStyle`s from §4.2 as `ThemeExtension<KairosType>`. Enable
      tabular figures on numeric styles.
- [ ] **5.** Build `HeroNumber` with the odometer roll. Write a widget test that the box
      width does not change between 9 and 10.
- [ ] **6.** Build `KairosSurface`, `SectionHeader`, `PrimaryButton`, `SecondaryButton`.
      Render them all on one debug screen and compare against §5 by eye.
- [ ] **7.** Build the three custom tab icons as `CustomPainter`s. Compare stroke weight to
      a 24pt reference square.
- [ ] **8.** Build the app shell: `Scaffold`, large-title behaviour, custom bottom nav,
      three empty tab routes. **This is the first visible milestone — the shell must
      already look designed before any feature exists.**

### Phase B — The three tabs (steps 9–15)

- [ ] **9.** Build `MomentCard` compact and hero. Hard-code three sample moments.
- [ ] **10.** Build the Next screen with all five states from §7.5, including the loading
      skeletons.
- [ ] **11.** Build the live clock block for Now, ticking, with tabular figures and the
      seconds field isolated in its own `ValueListenableBuilder`.
- [ ] **12.** Build `InstrumentTile` and the 2-column grid with the spanning fifth tile.
      Wire static micro-values.
- [ ] **13.** Build the Then memory grid with the staggered layout and the count-up unit
      chooser.
- [ ] **14.** Build both empty states to §7.4 / §9.3 exactly. Screenshot-compare the block's
      vertical position: it must start at 38% of viewport height.
- [ ] **15.** Review all three tabs against §23 acceptance criteria before proceeding.

### Phase C — Instruments (steps 16–24)

- [ ] **16.** Drift schema, repository, and the injectable `Clock`.
- [ ] **17.** Timezone service with bundled IANA data. Unit tests for DST and +5:30/+5:45.
- [ ] **18.** World clock: dial strip `CustomPainter` with the day/night arc.
- [ ] **19.** World clock: city rows with the day/night bar, date line, and offset in words.
- [ ] **20.** Alarm list, wake-window band, and the ring screen.
- [ ] **21.** Timer: ring, controls, presets, multi-stage.
- [ ] **22.** Stopwatch: monotonic engine, laps, and the lap delta line.
- [ ] **23.** Focus: ring, modes, sounds, heat map.
- [ ] **24.** Notification engine: channels, quiet hours, the reminder ladder.

### Phase D — Moments (steps 25–32)

- [ ] **25.** Moment editor sheet, all twelve fields, with validation.
- [ ] **26.** Moment detail screen with the three-column stat card.
- [ ] **27.** The tense state machine plus its tests, including the zero instant.
- [ ] **28.** The zero moment sequence, timed to §17.
- [ ] **29.** Recurrence engine: yearly, monthly, weekly, custom, lunar.
- [ ] **30.** Share cards at 9:16, 1:1, 16:9.
- [ ] **31.** Widget bridge contract and the JSON writer.
- [ ] **32.** Six widget designs on each platform.

### Phase E — Depth (steps 33–40)

- [ ] **33.** Themes: all 12, applied through the theme extension.
- [ ] **34.** Clock faces: 7, as `CustomPainter`s.
- [ ] **35.** Panchang and the additional calendars.
- [ ] **36.** Shared moments and sync.
- [ ] **37.** Live Activities and Android Live Updates.
- [ ] **38.** Apple Watch app and complications.
- [ ] **39.** Import and export, including the PDF memory book.
- [ ] **40.** Performance pass: 120Hz frame budget, cold start under 1.5s.

---

## 23. Acceptance criteria

A screen is done when every line below is true for it. Test on a real device at 100% text
size and at 310%.

**Global**
- [ ] No raw hex, raw size, or raw duration anywhere in `lib/features`.
- [ ] The amber accent appears exactly once per screen, on the live element.
- [ ] Every screen renders correctly in dark and light.
- [ ] Every screen renders correctly at 310% text scale with no truncation or overflow.
- [ ] Every screen has a defined empty, loading, and error state.
- [ ] Every tappable target is at least 44×44.
- [ ] Every countdown uses tabular figures — verified by holding the screen while it ticks.
- [ ] No shadow anywhere in dark mode.

**Per screen**
- [ ] Next: the hero number is the largest element; no second element competes with it.
- [ ] Next: the empty state block starts at 38% of viewport height, left-aligned, with a
      filled primary button.
- [ ] Now: a live time at 64pt is present at the top, ticking once per second.
- [ ] Now: five instrument tiles, each with a micro-value.
- [ ] Now: no big empty state anywhere inside a section.
- [ ] Then: numbers count up, and the unit changes with magnitude.
- [ ] World clock: every row shows a day/night bar, a date, and an offset in words.
- [ ] World clock: night cities render their time in `ink2`, not `ink1`.
- [ ] Every screen: content aligns to the 20pt margin; nothing drifts.

---

## 24. Copy deck

Use these strings verbatim. They are written to be short, warm, and specific. Do not
improvise alternatives.

**Empty states**
- Next headline: `Nothing ahead yet`
- Next body: `Add the day you are counting to. It will sit here, at the top of your day, until it happens.`
- Next action: `Add a moment`
- Then headline: `Nothing behind yet`
- Then body: `Moments move here once they pass, and count up from then on. Add one that already happened.`
- Then action: `Add a past date`
- Now, no ongoing: `No moment in progress.`

**Units**
- `day` / `days`, `sleep` / `sleeps`, `hour` / `hours`, `week` / `weeks`, `month` / `months`, `year` / `years`
- Percent: `58% there`
- Fraction: `12 of 30 classes`

**Zero moment**
- Default label: `It's here.`
- Memorial label: `Remembering.`

**Errors**
- Read failure: `Couldn't load your moments`
- Retry: `Try again`
- Past date warning: `That date has already passed — count up instead?`

**Never use**: `Oops`, `Uh oh`, `Something went wrong`, `Loading...`, `No data`,
`Welcome!`, or any string with an exclamation mark.

---

## 25. Anti-patterns: never do these

Each of these was present in the reviewed build. Each is a defect, not a preference.

| Never | Because | Instead |
|---|---|---|
| Use `NavigationBar` or `BottomNavigationBar` | Its pill indicator is the most recognisable Material default | The custom bar in §6.3 |
| Centre an empty state | It reads as a placeholder screen | Left-align at the margin, §7.4 |
| Use a 64pt grey glyph in an empty state | Reads as an error, not an invitation | 40pt accent-tinted glyph at 45% |
| Put the screen title in a fixed `AppBar` | Wastes 56pt on every screen forever | Large title that scrolls away, §6.2 |
| Use an hourglass anywhere | It means "waiting", and it was rejected for the app icon | The three custom glyphs, §5.8 |
| Show a spinner | It says nothing and looks unfinished | Skeletons, §7.5 |
| Use one grey for everything | Nothing separates; the screen reads flat | Five surface steps, §3.1 |
| Put body copy in `ink3` | Too low contrast; it looks disabled | `ink2` for body, `ink3` for labels only |
| Use the same font size for a number and its unit | The unit competes with the hero | Unit is always 20/26 600 `ink3` |
| Animate on first paint | Content should appear settled | Animate only in response to input |
| Use a linear curve on a card | Feels mechanical | The springs in §20.1 |
| Drop shadows in dark mode | Muddy, cheap, and unnecessary | Lightness steps, §3.4 |
| Let a number reflow as it ticks | The most obvious sign of an unfinished app | Tabular figures, Law 4 |
| Use `UTC+05:30` as the primary offset | Nobody thinks in UTC offsets | `5:30 ahead of you` |
| Show a city's time with no day/night signal | The screen exists to answer "can I call them" | Day/night bar, §10.3 |
| Put a marketing notification in the product | It is banned by the spec | No such notification exists |
| Use an icon font for the tab glyphs | It renders differently per OEM | `CustomPainter`, §5.8 |

---

*End of specification. When a screen and this document disagree, this document wins.
When this document is silent, log a decision in `STATUS.md` before inventing a rule.*
