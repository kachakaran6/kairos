# Kairos — Release & APK Distribution Guide

This document describes how to build, package, sign, and publish production releases of Kairos for Android.

---

## 1. Automated GitHub Actions Release (Recommended)

Kairos includes an automated CI/CD release pipeline ([`.github/workflows/release.yml`](.github/workflows/release.yml)) that builds universal APKs, architecture-specific split APKs, and Google Play App Bundles (AAB), computes SHA-256 checksums, and attaches them directly to a GitHub Release.

### Method A: Trigger by Git Tag
When you are ready to publish a new version:
```bash
# 1. Update version in pubspec.yaml (e.g., version: 1.0.0+1)
# 2. Commit the change
git commit -am "chore(release): bump version to 1.0.0"

# 3. Create and push a semantic git tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```
GitHub Actions will automatically run the release workflow, build all APKs, and publish the GitHub Release with downloadable assets.

### Method B: Manual Trigger via GitHub Web UI
1. Navigate to **Actions** in your GitHub repository.
2. Select **Build & Publish Release** in the left sidebar.
3. Click **Run workflow**, enter the version tag (e.g. `v1.0.0`), and click the green button.

---

## 2. Local Release Build Commands

To build production binaries on your local machine:

### Universal Release APK (All-in-one APK for sideloading)
```bash
flutter build apk --release
```
* **Output Path:** `build/app/outputs/flutter-apk/app-release.apk`
* **Compatible with:** Any modern Android device (ARM64, ARMv7, x86_64).

### Architecture-Specific Split APKs (Smaller file size)
```bash
flutter build apk --release --split-per-abi
```
* **Outputs:**
  * `app-arm64-v8a-release.apk` (modern 64-bit phones — smallest size)
  * `app-armeabi-v7a-release.apk` (older 32-bit phones)
  * `app-x86_64-release.apk` (tablets and emulators)

### Google Play App Bundle (AAB for Play Store distribution)
```bash
flutter build appbundle --release
```
* **Output Path:** `build/app/outputs/bundle/release/app-release.aab`

---

## 3. Package Name & Identity

* **Android Package / Application ID:** `com.samyukt.kairos`
* **iOS Bundle Identifier:** `com.samyukt.kairos`
* **Minimum Android SDK:** API 24 (Android 7.0)
* **Target Android SDK:** API 34+ (Android 14)

---

## 4. Production Code Signing (Optional)

By default, Flutter builds release APKs using standard configuration. For publishing on Google Play or distributing signed APKs:

1. **Generate a keystore:**
   ```bash
   keytool -genkey -v -keystore ~/kairos-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias kairos
   ```

2. **Create `android/key.properties` (this file is ignored by `.gitignore`):**
   ```properties
   storePassword=<your-store-password>
   keyPassword=<your-key-password>
   keyAlias=kairos
   storeFile=<path-to-your-keystore-file>
   ```

3. **Configure `android/app/build.gradle.kts` to load `key.properties` for production release.**
