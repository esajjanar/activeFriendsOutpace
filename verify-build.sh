#!/usr/bin/env bash
#
# verify-build.sh — First-time build setup + verification for Outpace.
#
# This script prepares the repo for building after a fresh clone or after
# running setup-repo.sh. It handles all the "gitignored but required" files.
#
# PREREQUISITES:
#   - Flutter SDK 3.13+ on PATH
#   - FlutterFire CLI: dart pub global activate flutterfire_cli
#   - A Firebase project with Android + iOS apps (bundle ID: app.activefriends.app)
#   - Xcode + CocoaPods (for iOS builds)
#   - Android SDK (for Android builds)
#
# USAGE:
#   cd /Users/I589392/mygit/activeFriendsOutpace
#   chmod +x verify-build.sh
#   ./verify-build.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"

# ─── Auto-source .env if present (gitignored — safe for credentials) ─────────
if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/.env"
  set +a
fi

red()  { printf '\033[31m%s\033[0m\n' "$*"; }
grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
ylw()  { printf '\033[33m%s\033[0m\n' "$*"; }
bold() { printf '\033[1m%s\033[0m\n' "$*"; }
fail() { red "✗ $*"; exit 1; }

PASS=0
WARN=0
FAIL=0

check_pass() { grn "  ✓ $*"; ((PASS++)); }
check_warn() { ylw "  ⚠ $*"; ((WARN++)); }
check_fail() { red "  ✗ $*"; ((FAIL++)); }

bold "═══════════════════════════════════════════════════"
bold "  Outpace — Build Verification"
bold "═══════════════════════════════════════════════════"
echo

# ─── Phase 1: Check prerequisites ───────────────────────────────────────────
bold "Phase 1: Prerequisites"

if command -v flutter &>/dev/null; then
  FLUTTER_VER="$(flutter --version 2>/dev/null | head -1)"
  check_pass "Flutter: $FLUTTER_VER"
else
  check_fail "Flutter SDK not found on PATH"
fi

if command -v dart &>/dev/null; then
  check_pass "Dart: $(dart --version 2>&1 | head -1)"
else
  check_fail "Dart SDK not found on PATH"
fi

echo

# ─── Phase 2: Check required files that are gitignored ──────────────────────
bold "Phase 2: Gitignored-but-required files"

# firebase_options.dart
if [ -f "$APP_DIR/lib/firebase_options.dart" ]; then
  check_pass "firebase_options.dart exists"
else
  check_fail "firebase_options.dart MISSING — run: cd app && flutterfire configure"
fi

# google-services.json (Android)
if [ -f "$APP_DIR/android/app/google-services.json" ]; then
  check_pass "google-services.json exists (Android)"
else
  check_fail "google-services.json MISSING — download from Firebase Console or run flutterfire configure"
fi

# GoogleService-Info.plist (iOS)
if [ -f "$APP_DIR/ios/Runner/GoogleService-Info.plist" ]; then
  check_pass "GoogleService-Info.plist exists (iOS)"
else
  check_fail "GoogleService-Info.plist MISSING — download from Firebase Console or run flutterfire configure"
fi

echo

# ─── Phase 3: Flutter pub get ───────────────────────────────────────────────
bold "Phase 3: Flutter dependencies"

cd "$APP_DIR"
echo "  → flutter pub get"
if flutter pub get 2>&1 | tail -3; then
  check_pass "flutter pub get succeeded"
else
  check_fail "flutter pub get failed"
fi

# Verify Generated.xcconfig was created
if [ -f "$APP_DIR/ios/Flutter/Generated.xcconfig" ]; then
  check_pass "ios/Flutter/Generated.xcconfig generated"
else
  check_fail "ios/Flutter/Generated.xcconfig NOT generated (flutter pub get may have failed)"
fi

echo

# ─── Phase 4: Flutter analyze ───────────────────────────────────────────────
bold "Phase 4: Static analysis"

echo "  → flutter analyze"
if flutter analyze --no-fatal-infos 2>&1 | tail -5; then
  check_pass "flutter analyze passed"
else
  check_warn "flutter analyze reported issues (review output above)"
fi

echo

# ─── Phase 5: Flutter test ──────────────────────────────────────────────────
bold "Phase 5: Tests"

echo "  → flutter test"
if flutter test 2>&1 | tail -10; then
  check_pass "flutter test passed"
else
  check_warn "flutter test reported failures (review output above)"
fi

echo

# ─── Phase 6: Android build (debug APK) ────────────────────────────────────
bold "Phase 6: Android debug build"

SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_KEY="${SUPABASE_PUBLISHABLE_KEY:-}"

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_KEY" ]; then
  ylw "  SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY not set."
  ylw "  Building WITHOUT backend (offline/UI-only mode)."
  echo "  → flutter build apk --debug"
  if flutter build apk --debug 2>&1 | tail -5; then
    check_pass "Android debug APK built (no backend)"
  else
    check_fail "Android debug APK build failed"
  fi
else
  echo "  → flutter build apk --debug (with Supabase)"
  if flutter build apk --debug \
       --dart-define=SUPABASE_URL="$SUPABASE_URL" \
       --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_KEY" 2>&1 | tail -5; then
    check_pass "Android debug APK built (with Supabase backend)"
  else
    check_fail "Android debug APK build failed"
  fi
fi

echo

# ─── Phase 7: iOS build (debug, simulator) ─────────────────────────────────
bold "Phase 7: iOS debug build"

if [[ "$(uname)" == "Darwin" ]]; then
  # Pod install first
  if [ -f "$APP_DIR/ios/Podfile" ]; then
    echo "  → pod install"
    cd "$APP_DIR/ios"
    if pod install 2>&1 | tail -5; then
      check_pass "pod install succeeded"
    else
      check_warn "pod install had issues (review output)"
    fi
    cd "$APP_DIR"
  fi

  if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_KEY" ]; then
    echo "  → flutter build ios --debug --simulator (no backend)"
    if flutter build ios --debug --simulator --no-codesign 2>&1 | tail -5; then
      check_pass "iOS simulator build succeeded (no backend)"
    else
      check_fail "iOS simulator build failed"
    fi
  else
    echo "  → flutter build ios --debug --simulator (with Supabase)"
    if flutter build ios --debug --simulator --no-codesign \
         --dart-define=SUPABASE_URL="$SUPABASE_URL" \
         --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_KEY" 2>&1 | tail -5; then
      check_pass "iOS simulator build succeeded (with Supabase backend)"
    else
      check_fail "iOS simulator build failed"
    fi
  fi
else
  check_warn "Not on macOS — skipping iOS build"
fi

echo

# ─── Summary ────────────────────────────────────────────────────────────────
bold "═══════════════════════════════════════════════════"
bold "  Results: $PASS passed, $WARN warnings, $FAIL failed"
bold "═══════════════════════════════════════════════════"
echo

if [ "$FAIL" -gt 0 ]; then
  red "Build verification FAILED — fix the issues above before proceeding."
  echo
  bold "Quick fix sequence:"
  echo "  1. cd app && flutterfire configure"
  echo "     (generates firebase_options.dart + downloads google-services.json + GoogleService-Info.plist)"
  echo "  2. flutter pub get"
  echo "  3. cd ios && pod install && cd .."
  echo "  4. Re-run this script"
  exit 1
elif [ "$WARN" -gt 0 ]; then
  ylw "Build verification passed with warnings — review before release."
  exit 0
else
  grn "All checks passed — ready for functional testing."
  exit 0
fi
