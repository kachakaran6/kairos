# Kairos — Google Play Store Listing Assets & Documentation

This directory contains the production-ready marketing assets, high-resolution app icon, and feature graphic for the **Kairos** Google Play Store listing.

All assets strictly comply with Google Play Developer Console requirements:
- **Screenshots (Phone)**: Minimum 2, maximum 8 pieces. Rendered in 1080 × 1920 px (9:16 aspect ratio, within the maximum allowed 2:1 ratio), 24-bit RGB PNG format.
- **Feature Graphic**: Exactly 1024 × 500 px, 24-bit RGB PNG, under 15 MB.
- **App Icon**: Exactly 512 × 512 px, 32-bit PNG with transparency, under 1024 KB.

---

## 1. Asset Inventory & Visual Narratives

| Filename | Resolution | Description & Focus |
|---|---|---|
| `01_warm_precision.png` | 1080 × 1920 | **WARM PRECISION** — Curated home widgets suite (Clock Monolith, Dashboard Combo) with real-time ticking typography, 28dp hardware-accelerated rounded corners, and luxury paper/ink palette. |
| `02_count_every_breath.png` | 1080 × 1920 | **COUNT EVERY BREATH** — Next Moment hero countdown with multi-scale unit progression, single high-contrast progress ring, and milestone anticipation. |
| `03_four_corners.png` | 1080 × 1920 | **FOUR CORNERS OF EARTH** — World Clock with 3D ray-sphere Earth globe and live astronomical solar terminator (day & night shadow). |
| `04_widget_studio.png` | 1080 × 1920 | **LIVE ON YOUR HOME SCREEN** — Interactive Widget Studio displaying 10 curated luxury Looks, Time Builder, Moment Builder, and live synchronization. |
| `05_alarm_wake_window.png` | 1080 × 1920 | **THE RHYTHM OF TIME** — Circadian awakening with 15-minute wake windows, volume ramps, 90-minute sleep cycles, and mindful dismissal challenges. |
| `06_deep_focus.png` | 1080 × 1920 | **DEEP FOCUS** — Ambient acoustic soundscapes (Rain on Zinc, Temple Drone, White Cedar) paired with 7-day streak density heat map. |
| `07_precision_timers.png` | 1080 × 1920 | **STOPWATCH & TIMERS** — Monotonic precision stopwatch with hundredth-second laps and concurrent countdown timers. |
| `08_time_travel.png` | 1080 × 1920 | **TIME TRAVEL SLIDER** — Planetary meeting planner with interactive solar elevation slider (-12h to +12h). |
| `feature_graphic.png` | 1024 × 500 | **PLAY STORE FEATURE GRAPHIC** — Editorial Warm Obsidian background, radial terracotta glow, brand typography *"KAIROS — Time, held gently."*, and luxury clock dial. |
| `app_icon_512.png` | 512 × 512 | **HIGH-RES APP ICON** — 512 × 512 px golden hour circular track with minimalist Kairos serif monogram. |

---

## 2. Play Store Compliance Checklist

- [x] **No Alpha in Screenshots**: Full 24-bit opaque RGB backgrounds (`#181513` to `#0C0A09`).
- [x] **Aspect Ratio**: 1080 × 1920 = 0.5625 (9:16), well under the 2:1 maximum limit.
- [x] **Feature Graphic**: Exactly 1024 × 500 px with no borders or transparent edges.
- [x] **High-Res Icon**: 512 × 512 px square format.
- [x] **Pristine Status Bar**: Android Demo Mode standard (10:00 AM, 100% battery, full signal, zero notification noise).
- [x] **Typography**: Warm Precision typography pairing display numerals with Fraunces / Grotesque serifs.

---

## 3. How to Regenerate or Update

To regenerate all store assets using Android SystemUI Demo Mode or the headless Skia rendering pipeline:

**Bash (Linux / macOS / Git Bash):**
```bash
./scripts/make_store_assets.sh [optional_device_id]
```

**PowerShell (Windows):**
```powershell
.\scripts\make_store_assets.ps1 -DeviceId "3086027538000H5"
```

Or run the test directly via Flutter:
```bash
flutter test test/generate_play_store_marketing_test.dart
```

---

## 4. Google Play Console Upload Instructions

1. Open **Google Play Console** -> Select your app (**Kairos**).
2. Navigate to **Grow** -> **Store presence** -> **Main store listing**.
3. Under **App icon**, upload `store_assets/app_icon_512.png`.
4. Under **Feature graphic**, upload `store_assets/feature_graphic.png`.
5. Under **Phone screenshots**, drag and drop all 8 screenshots (`01_warm_precision.png` through `08_time_travel.png`).
6. Click **Save** at the bottom of the page.
