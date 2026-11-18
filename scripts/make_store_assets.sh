#!/usr/bin/env bash
# make_store_assets.sh — Automates Google Play Store screenshot and graphic generation
# Follows AGENTS.md conventions and Play Store asset specifications.

set -euo pipefail

echo "=========================================================="
echo " Kairos — Google Play Store Marketing Asset Generation    "
echo "=========================================================="

DEVICE_ID="${1:-}"

if command -v adb >/dev/null 2>&1; then
  echo ">>> Configuring Android SystemUI Demo Mode for pristine status bar..."
  ADB_CMD="adb"
  if [ -n "$DEVICE_ID" ]; then
    ADB_CMD="adb -s $DEVICE_ID"
  fi

  # Enable demo mode
  $ADB_CMD shell settings put global sysui_demo_allowed 1 || true
  $ADB_CMD shell am broadcast -a com.android.systemui.demo -e command enter || true
  # Set clock to 10:00 (clean golden hour standard)
  $ADB_CMD shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 1000 || true
  # Battery 100% full, not charging
  $ADB_CMD shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false || true
  # Full WiFi signal
  $ADB_CMD shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4 || true
  # Clear notification icons
  $ADB_CMD shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false || true
  echo ">>> Device demo mode activated."
else
  echo ">>> adb not detected in path; proceeding with Flutter headless rendering engine."
fi

echo ">>> Rendering 8 composed 1080x1920 screenshots, 1024x500 feature graphic, and 512x512 app icon..."
flutter test test/generate_play_store_marketing_test.dart

if command -v adb >/dev/null 2>&1; then
  echo ">>> Exiting Android SystemUI Demo Mode..."
  $ADB_CMD shell am broadcast -a com.android.systemui.demo -e command exit || true
fi

echo ">>> Success! Assets saved to store_assets/:"
ls -lh store_assets/
echo "=========================================================="
