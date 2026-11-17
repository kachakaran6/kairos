# Contributing to Kairos

Thank you for your interest in contributing to Kairos! We welcome contributions from developers, designers, and documentation writers of all skill levels.

---

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

---

## Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (version `>=3.44.8` on the stable channel)
* [Dart SDK](https://dart.dev/get-dart)
* Android Studio / VS Code with Flutter extension
* An Android device or emulator (API 26+) or iOS Simulator (iOS 17+)

### Local Development Setup

1. **Fork and Clone the Repository:**
   ```bash
   git clone https://github.com/<your-username>/kairos.git
   cd kairos
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify Environment:**
   Run the test suite and quality gates:
   ```bash
   dart format --set-exit-if-changed .
   flutter analyze --fatal-infos
   flutter test
   dart run tool/check_tokens.dart
   dart run tool/check_strings.dart
   ```

4. **Run the Application:**
   ```bash
   flutter run
   ```

---

## Development Workflow

### 1. Branching Strategy
* Create a feature branch off `master`:
  ```bash
  git checkout -b feat/your-feature-name
  # or for fixes:
  git checkout -b fix/issue-description
  ```

### 2. Commit Message Conventions
We follow [Conventional Commits](https://www.conventionalcommits.org/):
* `feat(scope): add new feature`
* `fix(scope): resolve bug`
* `docs(scope): update documentation`
* `test(scope): add or update tests`
* `refactor(scope): internal code cleanup without feature changes`
* `chore(scope): update build configuration or tools`

### 3. Design & Architecture Rules
* **Tokens Only:** Never use hardcoded hex colors or magic spacing numbers in widgets. Use `KairosTheme.of(context)` tokens (`colours`, `typeScale`, `Space`, `RadiusTokens`).
* **State Management:** Riverpod `Notifier` and `AsyncNotifier`. Avoid global mutable state.
* **Time Arithmetic:** All internal time math must be in **UTC**. Local time is applied only at the UI render boundary.
* **Injectable Time:** In testable code, use the injectable `Clock` provider rather than calling `DateTime.now()` directly.
* **Quality Gates:** Before submitting a pull request, ensure:
  1. `dart format --set-exit-if-changed .` passes cleanly.
  2. `flutter analyze --fatal-infos` reports 0 issues.
  3. `flutter test` passes 100% green.
  4. `dart run tool/check_tokens.dart` passes with 0 violations.

---

## Pull Request Process

1. Push your branch to your GitHub fork:
   ```bash
   git push origin feat/your-feature-name
   ```
2. Open a Pull Request against the `master` branch.
3. Fill out the PR template with a clear description of your changes and test verification.
4. Ensure all CI checks pass. Maintainers will review and provide feedback.

---

## Good First Issues

Looking for a place to start? Check our issue tracker for issues with the `good first issue` label. These are self-contained tasks perfect for getting familiar with the codebase.
