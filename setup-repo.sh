#!/usr/bin/env bash
#
# setup-repo.sh — Selectively copy clean source files from the original
# activeFriends directory into this fresh open-source repo.
#
# USAGE:
#   cd /Users/I589392/mygit/activeFriendsOutpace
#   chmod +x setup-repo.sh
#   ./setup-repo.sh
#
# This script copies ONLY the files needed for a clean open-source release.
# It deliberately EXCLUDES:
#   - All keystores, credentials, service account files
#   - Database dumps, CSV exports, log files
#   - Build artifacts, IDE config, node_modules
#   - Personal screenshots and WhatsApp images
#   - LLM session handoff prompts with internal context
#
set -euo pipefail

SRC="/Users/I589392/mygit/activeFriends"
DST="/Users/I589392/mygit/activeFriendsOutpace"

red()  { printf '\033[31m%s\033[0m\n' "$*"; }
grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
bold() { printf '\033[1m%s\033[0m\n' "$*"; }

[ -d "$SRC" ] || { red "Source dir not found: $SRC"; exit 1; }
[ -d "$DST" ] || { red "Dest dir not found: $DST"; exit 1; }

bold "=== Setting up clean open-source repo ==="
echo "  Source: $SRC"
echo "  Dest:   $DST"
echo

# ─── 1. Flutter app source code ──────────────────────────────────────────────
bold "→ Copying Flutter app source (app/lib/)"
mkdir -p "$DST/app/lib"
rsync -a --exclude='firebase_options.dart' "$SRC/app/lib/" "$DST/app/lib/"
grn "  ✓ app/lib/ (excluding firebase_options.dart)"

# ─── 2. Flutter config files ─────────────────────────────────────────────────
bold "→ Copying Flutter config files"
cp "$SRC/app/pubspec.yaml" "$DST/app/"
cp "$SRC/app/analysis_options.yaml" "$DST/app/"
cp "$SRC/app/.metadata" "$DST/app/" 2>/dev/null || true
grn "  ✓ pubspec.yaml, analysis_options.yaml"

# ─── 3. Flutter app assets ───────────────────────────────────────────────────
bold "→ Copying app assets"
mkdir -p "$DST/app/assets"
cp "$SRC/app/assets/icon-lines-only.png" "$DST/app/assets/"
cp "$SRC/app/assets/offline_illustration.svg" "$DST/app/assets/"
grn "  ✓ app/assets/"

# ─── 4. Tests ────────────────────────────────────────────────────────────────
bold "→ Copying tests"
if [ -d "$SRC/app/test" ]; then
  mkdir -p "$DST/app/test"
  rsync -a "$SRC/app/test/" "$DST/app/test/"
  grn "  ✓ app/test/"
else
  red "  ⚠ No test directory found"
fi

# ─── 5. Android platform files (selective) ───────────────────────────────────
bold "→ Copying Android platform files (excluding secrets)"
mkdir -p "$DST/app/android/app/src/main/kotlin/app/activefriends/app"
mkdir -p "$DST/app/android/app/src/main/res"
mkdir -p "$DST/app/android/app/src/debug"
mkdir -p "$DST/app/android/app/src/profile"
mkdir -p "$DST/app/android/gradle/wrapper"

# Core gradle files
cp "$SRC/app/android/build.gradle.kts" "$DST/app/android/"
cp "$SRC/app/android/settings.gradle.kts" "$DST/app/android/"
cp "$SRC/app/android/gradle.properties" "$DST/app/android/"
cp "$SRC/app/android/gradlew" "$DST/app/android/"
cp "$SRC/app/android/gradlew.bat" "$DST/app/android/"
cp -r "$SRC/app/android/gradle/wrapper/" "$DST/app/android/gradle/wrapper/"

# App build file (no secrets — key.properties is loaded conditionally)
cp "$SRC/app/android/app/build.gradle.kts" "$DST/app/android/app/"

# Android source + resources
rsync -a "$SRC/app/android/app/src/main/kotlin/" "$DST/app/android/app/src/main/kotlin/"
rsync -a "$SRC/app/android/app/src/main/res/" "$DST/app/android/app/src/main/res/"
cp "$SRC/app/android/app/src/main/AndroidManifest.xml" "$DST/app/android/app/src/main/"
cp "$SRC/app/android/app/src/debug/AndroidManifest.xml" "$DST/app/android/app/src/debug/"
cp "$SRC/app/android/app/src/profile/AndroidManifest.xml" "$DST/app/android/app/src/profile/"

# Android .gitignore
cp "$SRC/app/android/.gitignore" "$DST/app/android/" 2>/dev/null || true

grn "  ✓ Android platform (no keystore, no key.properties, no google-services.json, no firebase admin SDK)"

# ─── 6. iOS platform files (selective) ───────────────────────────────────────
bold "→ Copying iOS platform files (excluding secrets)"
mkdir -p "$DST/app/ios/Runner/Assets.xcassets"
mkdir -p "$DST/app/ios/Runner/Base.lproj"
mkdir -p "$DST/app/ios/Runner.xcodeproj/project.xcworkspace"
mkdir -p "$DST/app/ios/Runner.xcodeproj/xcshareddata"
mkdir -p "$DST/app/ios/Runner.xcworkspace"
mkdir -p "$DST/app/ios/RunnerTests"
mkdir -p "$DST/app/ios/Flutter"

# Podfile (not Podfile.lock — let contributors regenerate)
cp "$SRC/app/ios/Podfile" "$DST/app/ios/"

# Xcode project
cp "$SRC/app/ios/Runner.xcodeproj/project.pbxproj" "$DST/app/ios/Runner.xcodeproj/"
rsync -a "$SRC/app/ios/Runner.xcodeproj/project.xcworkspace/" "$DST/app/ios/Runner.xcodeproj/project.xcworkspace/"
rsync -a "$SRC/app/ios/Runner.xcodeproj/xcshareddata/" "$DST/app/ios/Runner.xcodeproj/xcshareddata/"
# Skip xcuserdata/ — personal IDE state

# Xcode workspace
rsync -a --exclude='Pods' "$SRC/app/ios/Runner.xcworkspace/" "$DST/app/ios/Runner.xcworkspace/"

# Runner source files (excluding GoogleService-Info.plist)
cp "$SRC/app/ios/Runner/AppDelegate.swift" "$DST/app/ios/Runner/"
cp "$SRC/app/ios/Runner/SceneDelegate.swift" "$DST/app/ios/Runner/"
cp "$SRC/app/ios/Runner/Info.plist" "$DST/app/ios/Runner/"
cp "$SRC/app/ios/Runner/Runner.entitlements" "$DST/app/ios/Runner/"
cp "$SRC/app/ios/Runner/Runner-Bridging-Header.h" "$DST/app/ios/Runner/"
cp "$SRC/app/ios/Runner/GeneratedPluginRegistrant.h" "$DST/app/ios/Runner/"
cp "$SRC/app/ios/Runner/GeneratedPluginRegistrant.m" "$DST/app/ios/Runner/"

# iOS assets (app icons, launch images)
rsync -a "$SRC/app/ios/Runner/Assets.xcassets/" "$DST/app/ios/Runner/Assets.xcassets/"
rsync -a "$SRC/app/ios/Runner/Base.lproj/" "$DST/app/ios/Runner/Base.lproj/"

# ExportOptions.plist — contains Team ID which is not a secret per se,
# but contributors will need their own. Copy it with a note.
cp "$SRC/app/ios/ExportOptions.plist" "$DST/app/ios/"

# iOS .gitignore
cp "$SRC/app/ios/.gitignore" "$DST/app/ios/" 2>/dev/null || true

# Flutter generated configs (needed for build)
cp "$SRC/app/ios/Flutter/AppFrameworkInfo.plist" "$DST/app/ios/Flutter/" 2>/dev/null || true

# RunnerTests
rsync -a "$SRC/app/ios/RunnerTests/" "$DST/app/ios/RunnerTests/" 2>/dev/null || true

grn "  ✓ iOS platform (no GoogleService-Info.plist, no Pods, no .symlinks, no build artifacts)"

# ─── 7. Supabase backend ─────────────────────────────────────────────────────
bold "→ Copying Supabase backend"
mkdir -p "$DST/supabase/migrations"
mkdir -p "$DST/supabase/functions"
mkdir -p "$DST/supabase/fixtures"

cp "$SRC/supabase/config.toml" "$DST/supabase/"
rsync -a "$SRC/supabase/migrations/" "$DST/supabase/migrations/"
rsync -a "$SRC/supabase/functions/" "$DST/supabase/functions/"
rsync -a "$SRC/supabase/fixtures/" "$DST/supabase/fixtures/"

grn "  ✓ supabase/ (config, migrations, edge functions, fixtures)"

# ─── 8. Design / architecture documentation ──────────────────────────────────
bold "→ Copying documentation (safe docs only)"
mkdir -p "$DST/docs"

# These docs are safe and valuable for contributors:
cp "$SRC/activeFriends — Detailed User Flows.md" "$DST/docs/user-flows.md"
cp "$SRC/activeFriends — Sequence Diagrams.md" "$DST/docs/sequence-diagrams.md"
cp "$SRC/activeFriends — Design Tokens (Lagoon Teal).md" "$DST/docs/design-tokens.md"

# Useful issue docs (no PII)
cp "$SRC/docs/health-connect-pixel9-issue.md" "$DST/docs/" 2>/dev/null || true
cp "$SRC/issues/ios-push-notifications.md" "$DST/docs/" 2>/dev/null || true
cp "$SRC/issues/notifications-gemini.md" "$DST/docs/" 2>/dev/null || true
cp "$SRC/issues/watch-import-resume.md" "$DST/docs/" 2>/dev/null || true

# Architecture diagram source (drawio)
cp "$SRC/assets/outpace-architecture-v2.drawio" "$DST/docs/" 2>/dev/null || true
cp "$SRC/outpace-architecture-v2.drawio.png" "$DST/docs/" 2>/dev/null || true

grn "  ✓ docs/ (user flows, sequence diagrams, design tokens, architecture)"

# ─── 9. App icons only from assets ───────────────────────────────────────────
bold "→ Copying app icons"
mkdir -p "$DST/assets/icons"
rsync -a "$SRC/assets/icons/" "$DST/assets/icons/"
grn "  ✓ assets/icons/"

# ─── 10. Store assets (icon only, no screenshots with real user data) ────────
bold "→ Copying store assets (icon only)"
mkdir -p "$DST/store-assets"
cp "$SRC/store-assets/app_icon_512.png" "$DST/store-assets/"
cp "$SRC/store-assets/feature_graphic.png" "$DST/store-assets/"
cp "$SRC/store-assets/feature_graphic.html" "$DST/store-assets/"
grn "  ✓ store-assets/ (app icon + feature graphic only — no screenshots)"

# ─── 11. HTML explorers (design reference, no secrets) ───────────────────────
bold "→ Copying design explorers"
cp "$SRC/activeFriends Feed Card Explorer.html" "$DST/docs/" 2>/dev/null || true
cp "$SRC/activeFriends Theme Explorer.html" "$DST/docs/" 2>/dev/null || true
cp "$SRC/activeFriends Track Control Explorer.html" "$DST/docs/" 2>/dev/null || true
grn "  ✓ Design explorers → docs/"

# ─── 12. Flutter .gitignore ──────────────────────────────────────────────────
cp "$SRC/app/.gitignore" "$DST/app/" 2>/dev/null || true

# ─── Done ────────────────────────────────────────────────────────────────────
echo
bold "=== Copy complete ==="
echo
bold "Files NOT copied (by design):"
echo "  ✗ upload-keystore.jks (3 copies)"
echo "  ✗ key.properties, local.properties"
echo "  ✗ google-services.json (2 copies)"
echo "  ✗ GoogleService-Info.plist"
echo "  ✗ firebase_options.dart"
echo "  ✗ outpace-ab523-firebase-adminsdk-*.json"
echo "  ✗ *.dump, *.sql (database dumps)"
echo "  ✗ csv24_09/ (user data exports)"
echo "  ✗ supabase_logs.json"
echo "  ✗ HANDOVER_iOS_submission.md"
echo "  ✗ Implementation Resume Prompts"
echo "  ✗ docs/session-resume-*.md, password-reset-claude-handoff.md"
echo "  ✗ Personal images (IMG-*.jpg, Screenshot_*.png, *.mp4)"
echo "  ✗ node_modules/, .dart_tool/, build/, .gradle/, Pods/"
echo "  ✗ .idea/, .vscode/, .superpowers/"
echo "  ✗ graphify-out/, package.json/lock (root-level node)"
echo "  ✗ app/build_release.sh (superseded, had hardcoded secrets)"
echo
bold "Next steps:"
echo "  1. Review the sanitized build scripts (build-aab.sh, build-ipa.sh)"
echo "  2. Review generated files (README.md, CONTRIBUTING.md, LICENSE, .gitignore)"
echo "  3. Run: cd $DST && git init && git add -A && git commit -m 'Initial open-source release'"
echo "  4. Create a GitHub repo and push"
echo "  5. Rotate your secrets (Supabase key, Firebase Admin key, keystore)"
