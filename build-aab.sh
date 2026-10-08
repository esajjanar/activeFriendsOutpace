#!/usr/bin/env bash
#
# build-aab.sh — Build a RELEASE Android App Bundle for Outpace, the safe way.
#
# WHY THIS EXISTS
#   The app reads SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY via
#   String.fromEnvironment (compile-time constants). A build WITHOUT these
#   --dart-defines does NOT crash: main.dart wraps init in
#   `if (SupabaseConfig.isConfigured)`, so it silently SKIPS Supabase.initialize()
#   and ships an app with no backend (no auth, no feed, no data).
#   That silent failure has cost ~8h across two incidents.
#
#   This script ALWAYS passes the defines, ALWAYS cleans first, and then VERIFIES
#   the values were actually compiled into the binary before declaring success.
#   If the defines didn't take effect, it fails loudly and tells you NOT to upload.
#
# USAGE
#   export SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co"
#   export SUPABASE_PUBLISHABLE_KEY="your_anon_key"
#   ./build-aab.sh
#   (Bump `version:` in app/pubspec.yaml first if Play rejects the versionCode.)
#
set -euo pipefail

# ─── Config: MUST be set via environment variables ───────────────────────────
SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_PUBLISHABLE_KEY="${SUPABASE_PUBLISHABLE_KEY:-}"
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"
AAB="$APP_DIR/build/app/outputs/bundle/release/app-release.aab"

red()  { printf '\033[31m%s\033[0m\n' "$*"; }
grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
bold() { printf '\033[1m%s\033[0m\n' "$*"; }
fail() { red "✗ $*"; exit 1; }

# ─── Preflight ───────────────────────────────────────────────────────────────
[ -n "$SUPABASE_URL" ]             || fail "SUPABASE_URL is not set — export it before running this script."
[ -n "$SUPABASE_PUBLISHABLE_KEY" ] || fail "SUPABASE_PUBLISHABLE_KEY is not set — export it before running this script."
[ -d "$APP_DIR" ]                  || fail "Flutter app dir not found at $APP_DIR"

cd "$APP_DIR"
VERSION="$(grep '^version:' pubspec.yaml | awk '{print $2}')"

bold "Building Outpace release AAB"
echo "  App dir : $APP_DIR"
echo "  Version : $VERSION   (versionCode = the number after '+')"
echo "  Supabase: $SUPABASE_URL"
echo

# ─── Clean + build ───────────────────────────────────────────────────────────
echo "→ flutter clean"
flutter clean >/dev/null

echo "→ flutter build appbundle --release (with dart-defines)"
flutter build appbundle --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY"

# ─── Verify the defines were actually compiled into the binary ───────────────
[ -f "$AAB" ] || fail "Build reported success but AAB not found at $AAB"

HOST="${SUPABASE_URL#https://}"
KEY_CHUNK="${SUPABASE_PUBLISHABLE_KEY:0:25}"   # app-specific prefix, not a generic literal
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
unzip -o -q "$AAB" 'base/lib/arm64-v8a/libapp.so' -d "$TMP" \
  || fail "Could not extract libapp.so from AAB"
SO="$TMP/base/lib/arm64-v8a/libapp.so"

# Dump strings to a file ONCE, then grep the file (no pipe).
# Why not `strings "$SO" | grep -q`: under `set -o pipefail`, grep -q finds the
# match and closes the pipe early, strings then dies with SIGPIPE (141), and
# pipefail reports the pipeline as FAILED even though the match WAS found —
# a false "DO NOT UPLOAD". Grepping a plain file avoids the pipe entirely.
strings -n 6 "$SO" > "$TMP/app.strings"
grep -qF "$HOST" "$TMP/app.strings" \
  || fail "Supabase URL host ($HOST) NOT in compiled binary — dart-defines did not take effect. DO NOT UPLOAD."
grep -qF "$KEY_CHUNK" "$TMP/app.strings" \
  || fail "Supabase publishable key NOT in compiled binary — dart-defines did not take effect. DO NOT UPLOAD."

# ─── Success ─────────────────────────────────────────────────────────────────
echo
grn "✓ Verified: Supabase URL + publishable key are compiled into the binary."
grn "✓ AAB ready ($VERSION):"
echo "    $AAB"
ls -la "$AAB" | awk '{print "    size:", $5, "bytes   built:", $6, $7, $8}'
echo
bold "Next: Play Console → Closed testing (Alpha) → Create new release → upload this file."
