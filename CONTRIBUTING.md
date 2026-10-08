# Contributing to Outpace

Thanks for your interest in contributing. This guide covers everything you need to get started.

## Prerequisites

- Flutter SDK 3.13+ (includes Dart 3.13+)
- Android Studio or Xcode (for platform builds)
- Supabase CLI (`npm install -g supabase` or use `npx supabase`)
- A Supabase project (free tier is fine for development)
- A Firebase project with FCM enabled

## Development Setup

### 1. Fork and clone

```bash
git clone https://github.com/YOUR_USERNAME/activeFriendsOutpace.git
cd activeFriendsOutpace
```

### 2. Install Flutter dependencies

```bash
cd app
flutter pub get
```

### 3. Set up your Supabase instance

```bash
cd supabase
npx supabase link --project-ref YOUR_PROJECT_REF
npx supabase db push
```

For local development with Supabase CLI:

```bash
npx supabase start       # Starts local Supabase (Docker required)
npx supabase db reset     # Apply migrations + seed data
```

### 4. Configure Firebase

Follow the [Firebase setup instructions](README.md#3-set-up-firebase) in the README. Each contributor needs their own Firebase project.

### 5. Run the app

```bash
cd app
flutter run \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your_local_anon_key
```

## Code Architecture

The app follows a **feature-slice** architecture:

```
lib/
  core/         → App shell, theme, config, shared widgets
  data/         → Local database (Drift/SQLite), data services
  features/     → Feature modules (auth, feed, tracking, etc.)
    each feature/
      data/           → Repositories, models
      presentation/   → Screens, widgets
```

### State Management

The codebase uses `StatefulWidget` + `setState` throughout. There is no Provider, Riverpod, or Bloc layer. This is intentional for simplicity but may evolve. If you want to introduce a state management solution, please open an issue for discussion first.

### Key Design Decisions

- **Supabase config via compile-time defines**: `SupabaseConfig` reads `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` from `String.fromEnvironment`. The app gracefully degrades to offline-only mode if these are not set.
- **Offline-first**: All activity data is stored locally in SQLite (Drift) and synced to Supabase. The app should work without connectivity.
- **Health data stays on device**: We use Health Connect / HealthKit for wearable import. No vendor cloud APIs are used — data never leaves the phone via third-party APIs.

## Code Style

- Follow the existing style — the project uses `flutter_lints` (standard rules)
- Run `flutter analyze` before submitting — zero warnings expected
- Use `///` doc comments on all new public classes and methods
- Keep widgets focused: one widget per file, named after the widget

## Running Tests

```bash
cd app
flutter test
```

### Regenerating Drift database code

If you modify `app/lib/data/local/app_database.dart`, regenerate the generated code:

```bash
cd app
dart run build_runner build --delete-conflicting-outputs
```

## Submitting Changes

1. Create a feature branch from `main`
2. Make your changes with clear, focused commits
3. Run `flutter analyze` and `flutter test`
4. Open a pull request with:
   - A clear description of what changed and why
   - Screenshots for UI changes
   - Test coverage for new logic

## Supabase Migrations

If your change requires a database schema change:

1. Create a new migration file:
   ```bash
   cd supabase
   npx supabase migration new your_migration_name
   ```
2. Write the SQL in the generated file under `supabase/migrations/`
3. Test locally: `npx supabase db reset`
4. Include the migration in your PR

## Edge Functions

Edge functions live in `supabase/functions/`. Each function is a Deno TypeScript module.

To test locally:

```bash
cd supabase
npx supabase functions serve function-name --env-file .env.local
```

Deploy:

```bash
npx supabase functions deploy function-name
```

## Areas Where Help Is Needed

- **Test coverage**: The app has minimal tests — unit tests for business logic and widget tests for key screens are very welcome
- **Accessibility**: Screen reader support, semantic labels, contrast improvements
- **Localization**: The app is English-only; i18n infrastructure would be valuable
- **Documentation**: Inline code documentation, architecture decision records

## Code of Conduct

Be respectful. Be constructive. We're here to build something useful together.
