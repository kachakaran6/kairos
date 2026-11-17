# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Relational SQLite persistence via Drift with schema migrations.
- Concurrent multi-stage timer recipes.
- Native iOS Lock Screen & Home Screen widgets via SwiftUI / WidgetKit.
- Native Android widgets via Jetpack Glance.

## [1.0.0] - 2026-11-17

### Added
- **Three-Tense Architecture**:
  - `Next`: Upcoming moments and countdowns with visual category badges and circular progress indicators.
  - `Now`: Real-time dashboard featuring oversized 10:30.00 clock with seconds, tabular numerals, and live instrument statuses.
  - `Then`: Historical timeline with elapsed count-up cards and hairline chronological markers.
- **5 Baseline Time Instruments**:
  - `World Clock`: Interactive 3D orthographic globe with day/night solar terminator and time-travel slider.
  - `Alarm`: Complete alarm scheduler with 90-minute sleep cycle recommendations, gradual volume ramp, and shake/math dismissal challenges.
  - `Timer`: 290pt progress track with rapid presets and pause/resume controls.
  - `Stopwatch`: Analog dial with precision sweeping hand, centisecond counter, and lap tracking.
  - `Focus`: 25-minute Pomodoro sessions, 5 ambient soundscapes (Rain, White Noise, Forest, Cafe), and a 7-day streak heatmap.
- **Moments Engine**:
  - Full CRUD for countdowns, count-ups, ongoing events, pinned priorities, and category tagging.
  - The Zero Moment: Full-screen celebration sequence with radial light bloom, confetti particle physics, and haptics.
- **Design System ("Warm Precision")**:
  - Centralized design tokens for color, typography, spacing (4pt/8pt grid), continuous squircle radii (28pt cards, 20pt inputs, pill buttons).
  - 5 customizable accent themes: Terracotta, Ocean Blue, Forest Green, Lavender, and Graphite.
  - First-class Dark and Light modes meeting WCAG AA contrast.
  - Tabular typography ensuring clock numerals never jitter or reflow.
- **Regional Calendars**:
  - Integrated Vikram Samvat, Islamic Hijri, and lunar phase calculations.
- **Local-First & Offline Architecture**:
  - Zero required accounts, zero advertisements, and 100% offline functionality.
