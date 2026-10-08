#!/usr/bin/env bash
#
# build-ipa.sh — Build a RELEASE IPA for Outpace (TestFlight / App Store), the safe way.
#
# WHY THIS EXISTS
#   Same reason as build-aab.sh: the app reads SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY
#   via String.fromEnvironment (compile-time constants). Building WITHOUT these
#   --dart-defines ships an app with no backend — silent failure.
#
#   This script:
#   1. Ensures dart-defines are ALWAYS passed
#   2. Runs `pod install` (Podfile.lock has been stale before — cost hours)
#   3. Builds the IPA via `flutter build ipa`
#   4. Verifies the defines were compiled into the App.framework binary
#   5. Reminds you to upload via Transporter / Xcode
#
# USAGE
#   export SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co"
#   export SUPABASE_PUBLISHABLE_KEY="your_anon_key"
#   ./build-ipa.sh
#   (Bump `version:` in app/pubspec.yaml first if App Store rejects the build number.)
#
set -euo pipefail

# ─── Config: MUST be set via environment variables ───────────────────────────
SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_PUBLISHABLE_KEY="${SUPABASE_PUBLISHABLE_KEY:-}"
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"
IPA_DIR="$APP_DIR/build/ios/ipa"
EXPORT_OPTIONS="$APP_DIR/ios/ExportOptions.plist"

red()  { printf '\033[31m%s\033[0m\n' "$*"; }
grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
bold() { printf '\033[1m%s\033[0m\n' "$*"; }
fail() { red "✗ $*"; exit 1; }

# ─── Preflight ───────────────────────────────────────────────────────────────
[ -n "$SUPABASE_URL" ]             || fail "SUPABASE_URL is not set — export it before running this script."
[ -n "$SUPABASE_PUBLISHABLE_KEY" ] || fail "SUPABASE_PUBLISHABLE_KEY is not set — export it before running this script."
[ -d "$APP_DIR" ]                  || fail "Flutter app dir not found at $APP_DIR"
[ -f "$EXPORT_OPTIONS" ]           || fail "ExportOptions.plist not found at $EXPORT_OPTIONS — needed for HealthKit + Push Notifications signing."

cd "$APP_DIR"
VERSION="$(grep '^version:' pubspec.yaml | awk '{print $2}')"

bold "Building Outpace release IPA"
echo "  App dir : $APP_DIR"
echo "  Version : $VERSION   (build number = the number after '+')"
echo "  Supabase: $SUPABASE_URL"
echo

# ─── Preflight: aps-environment must be 'production' for TestFlight / App Store ─
# With manual signing, Xcode does NOT rewrite this at export time. If it says
# 'development', the device registers with the APNs sandbox server but FCM sends
# to the production server — push notifications are silently dropped.
ENTITLEMENTS="$APP_DIR/ios/Runner/Runner.entitlements"
[ -f "$ENTITLEMENTS" ] || fail "Runner.entitlements not found at $ENTITLEMENTS"
grep -q '<string>production</string>' "$ENTITLEMENTS" \
  || fail "Runner.entitlements has aps-environment != 'production'. Push notifications will be silently dropped on TestFlight/App Store. Fix it first."
grn "✓ aps-environment = production"

# ─── Pod install (critical — stale Podfile.lock has caused issues before) ────
echo "→ pod install"
cd ios
pod install --repo-update
cd ..
grn "✓ Pods installed"

# ─── Clean + build ───────────────────────────────────────────────────────────
echo "→ flutter clean"
flutter clean >/dev/null

echo "→ flutter build ipa --release (with dart-defines)"
flutter build ipa --release \
  --export-options-plist="$EXPORT_OPTIONS" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY"

# ─── Find the IPA ────────────────────────────────────────────────────────────
IPA="$(find "$IPA_DIR" -name '*.ipa' -print -quit 2>/dev/null || true)"
[ -n "$IPA" ] && [ -f "$IPA" ] || fail "Build reported success but no .ipa found in $IPA_DIR"

# ─── Verify the defines were compiled into the App.framework binary ──────────
HOST="${SUPABASE_URL#https://}"
KEY_CHUNK="${SUPABASE_PUBLISHABLE_KEY:0:25}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# IPA is a zip — extract the App framework binary
unzip -o -q "$IPA" 'Payload/*/Frameworks/App.framework/App' -d "$TMP" \
  || fail "Could not extract App.framework from IPA"
APP_BIN="$(find "$TMP/Payload" -path '*/App.framework/App' -print -quit)"
[ -n "$APP_BIN" ] && [ -f "$APP_BIN" ] || fail "App.framework binary not found in extracted IPA"

strings -n 6 "$APP_BIN" > "$TMP/app.strings"
grep -qF "$HOST" "$TMP/app.strings" \
  || fail "Supabase URL host ($HOST) NOT in compiled binary — dart-defines did not take effect. DO NOT UPLOAD."
grep -qF "$KEY_CHUNK" "$TMP/app.strings" \
  || fail "Supabase publishable key NOT in compiled binary — dart-defines did not take effect. DO NOT UPLOAD."

# ─── Success ─────────────────────────────────────────────────────────────────
echo
grn "✓ Verified: Supabase URL + publishable key are compiled into the binary."
grn "✓ aps-environment = production (APNs production server — push notifications will work)."
grn "✓ IPA ready ($VERSION):"
echo "    $IPA"
ls -la "$IPA" | awk '{print "    size:", $5, "bytes   built:", $6, $7, $8}'
echo
bold "Next: Open Transporter.app → drag the IPA → upload to App Store Connect."
bold "  Or: xcrun altool --upload-app -f \"$IPA\" -t ios -u YOUR_APPLE_ID -p YOUR_APP_SPECIFIC_PASSWORD"
