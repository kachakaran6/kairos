# make_store_assets.ps1 — Automates Google Play Store screenshot and graphic generation
# Follows AGENTS.md conventions and Play Store asset specifications.

param(
    [string]$DeviceId = ""
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Kairos — Google Play Store Marketing Asset Generation    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$adb = Get-Command "adb" -ErrorAction SilentlyContinue

if ($adb) {
    Write-Host ">>> Configuring Android SystemUI Demo Mode for pristine status bar..." -ForegroundColor Yellow
    $adbArgs = if ($DeviceId) { @("-s", $DeviceId) } else { @() }

    & adb $adbArgs shell settings put global sysui_demo_allowed 1
    & adb $adbArgs shell am broadcast -a com.android.systemui.demo -e command enter
    & adb $adbArgs shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 1000
    & adb $adbArgs shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
    & adb $adbArgs shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4
    & adb $adbArgs shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false
    Write-Host ">>> Device demo mode activated." -ForegroundColor Green
} else {
    Write-Host ">>> adb not detected in path; proceeding with Flutter headless rendering engine." -ForegroundColor Yellow
}

Write-Host ">>> Rendering 8 composed 1080x1920 screenshots, 1024x500 feature graphic, and 512x512 app icon..." -ForegroundColor Cyan
flutter test test/generate_play_store_marketing_test.dart

if ($adb) {
    Write-Host ">>> Exiting Android SystemUI Demo Mode..." -ForegroundColor Yellow
    & adb $adbArgs shell am broadcast -a com.android.systemui.demo -e command exit
}

Write-Host ">>> Success! Assets saved to store_assets/:" -ForegroundColor Green
Get-ChildItem -Path "store_assets" | Format-Table Name, Length, LastWriteTime
Write-Host "==========================================================" -ForegroundColor Cyan
