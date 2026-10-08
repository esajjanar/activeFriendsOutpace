# Outpace

A minimal, invite-only activity app for friends clubs. Replace your Strava club + manual WhatsApp leaderboard with zero-effort tracking and weekly rituals.

**Core principle: the app is an aggregator, not a tracker.** Members' watches are the source of truth; the app collects, scores, ranks, and shares.

## What It Does

- **Import activities from wearables** via Health Connect (Android) / HealthKit (iOS) — Garmin, Fitbit, Samsung Health, Apple Watch, Polar, Coros, and more
- **Phone GPS recording** for run / walk / cycle (fallback for watch-less members)
- **Manual log** for strength training (duration, no GPS)
- **Weekly leaderboard** with a fair cross-activity points system
- **Activity feed** with reactions and comments (club members only)
- **Push notifications** via FCM with AI-generated creative copy (Gemini Flash)
- **Weekly summary card** → WhatsApp share sheet
- **Offline-first**: local SQLite via Drift, background sync to Supabase

## Tech Stack

| Layer | Technology |
|---|---|
| **Mobile** | Flutter (Android + iOS) |
| **Backend** | Supabase (Postgres, Auth, Realtime, Edge Functions, Storage) |
| **Local DB** | Drift (SQLite) |
| **Push** | Firebase Cloud Messaging (FCM) |
| **AI** | Google Gemini Flash (notification copy generation) |
| **Health Data** | Health Connect (Android), HealthKit (iOS) |

## Architecture

```
┌─────────────────────────────────────────────┐
│  Flutter App (app/)                         │
│  ┌─────────┐  ┌──────────┐  ┌───────────┐  │
│  │ features│  │  core/   │  │   data/   │  │
│  │ auth    │  │  theme   │  │   local   │  │
│  │ feed    │  │  config  │  │   (Drift) │  │
│  │ tracking│  │  widgets │  │   services│  │
│  │ clubs   │  └──────────┘  └─────┬─────┘  │
│  │ ...     │                      │        │
│  └─────────┘                      │        │
└───────────────────────────────────┼────────┘
                                    │ sync
┌───────────────────────────────────┼────────┐
│  Supabase (supabase/)             │        │
│  ┌────────────┐  ┌────────────────┘──────┐ │
│  │ Postgres   │  │ Edge Functions        │ │
│  │ + Auth     │  │ send-push             │ │
│  │ + Realtime │  │ send-activity-notif   │ │
│  │ + Storage  │  │ send-daily-nudge      │ │
│  └────────────┘  │ send-weekly-reminder  │ │
│                  │ verify-email          │ │
│                  │ delete-account        │ │
│                  └───────────────────────┘ │
└────────────────────────────────────────────┘
```

See [`docs/`](docs/) for detailed user flows, sequence diagrams, and design tokens.

## Prerequisites

- **Flutter SDK** 3.13+ (Dart 3.13+)
- **Supabase CLI** (`npx supabase` or installed globally)
- **Firebase project** with FCM enabled (Android + iOS)
- **Android Studio** or **Xcode** for platform-specific builds
- A Supabase project (free tier works)

## Getting Started

### 1. Clone and install dependencies

```bash
git clone https://github.com/YOUR_USERNAME/activeFriendsOutpace.git
cd activeFriendsOutpace/app
flutter pub get
```

### 2. Set up Supabase

Create a Supabase project at [supabase.com](https://supabase.com), then:

```bash
cd supabase
npx supabase link --project-ref YOUR_PROJECT_REF
npx supabase db push        # Apply all migrations
npx supabase functions deploy  # Deploy all edge functions
```

Set the required edge function secrets:

```bash
npx supabase secrets set \
  FCM_SERVICE_ACCOUNT_KEY='<your-firebase-admin-sdk-json>' \
  BREVO_API_KEY='<your-brevo-transactional-email-key>' \
  BREVO_FROM_EMAIL='noreply@yourdomain.com' \
  GEMINI_API_KEY='<your-google-ai-key>'
```

### 3. Set up Firebase

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add Android and iOS apps with bundle ID `app.activefriends.app` (or your own)
3. Download `google-services.json` → `app/android/app/`
4. Download `GoogleService-Info.plist` → `app/ios/Runner/`
5. Generate Firebase options:

```bash
cd app
flutterfire configure
```

This creates `lib/firebase_options.dart` (gitignored — each contributor generates their own).

### 4. Build and run

**Debug (no backend — UI-only mode):**
```bash
cd app
flutter run
```

**With backend (Supabase connected):**
```bash
cd app
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your_anon_key
```

**Release builds** — use the provided build scripts:
```bash
# Set env vars first
export SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co"
export SUPABASE_PUBLISHABLE_KEY="your_anon_key"

./build-aab.sh   # Android App Bundle
./build-ipa.sh   # iOS IPA
```

### 5. Android signing (release builds)

Create `app/android/key.properties` from the template:

```bash
cp app/android/key.properties.example app/android/key.properties
# Edit with your keystore details
```

## Project Structure

```
activeFriendsOutpace/
├── app/                    # Flutter application
│   ├── lib/
│   │   ├── core/           # App shell, theme, config, shared widgets
│   │   ├── data/           # Local database (Drift), services
│   │   └── features/       # Feature modules
│   │       ├── auth/       # Email + password auth (Supabase Auth)
│   │       ├── feed/       # Club activity feed with reactions/comments
│   │       ├── tracking/   # GPS tracker + Health Connect/HealthKit import
│   │       ├── leaderboard/# Weekly points leaderboard
│   │       ├── clubs/      # Club management, invite codes
│   │       ├── profile/    # User profile, avatar
│   │       ├── notifications/
│   │       ├── onboarding/
│   │       ├── import/     # Wearable data import
│   │       ├── home/       # Bottom nav shell
│   │       └── bootstrap/  # App initialization
│   ├── test/               # Unit and widget tests
│   ├── android/            # Android platform config
│   └── ios/                # iOS platform config
├── supabase/               # Supabase backend
│   ├── config.toml         # Local dev config
│   ├── migrations/         # Database schema (46 migrations)
│   ├── functions/          # Edge functions (6)
│   └── fixtures/           # Dev seed data
├── docs/                   # Architecture docs, user flows, diagrams
├── build-aab.sh            # Android release build (with verification)
├── build-ipa.sh            # iOS release build (with verification)
└── store-assets/           # App icon, feature graphic
```

## Known Issues

This project is functional but in active development. Known areas that need work:

- [ ] Test coverage is low — contributions welcome
- [ ] No state management library (uses StatefulWidget + setState throughout)
- [ ] `app_database.g.dart` is generated by Drift — regenerate with `dart run build_runner build`
- [ ] Health Connect on Pixel 9 with Android 14+ requires compileSdk 36 (already configured)
- [ ] iOS push notifications require `aps-environment = production` in entitlements for TestFlight

See [docs/](docs/) for detailed issue notes.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup instructions, code style, and PR guidelines.

## License

[MIT](LICENSE)
