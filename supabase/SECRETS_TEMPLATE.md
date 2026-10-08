# Supabase Edge Function Secrets

The edge functions require the following secrets to be set. For local development, create a `.env.local` file in this directory. For production, use `npx supabase secrets set`.

## Required Secrets

### `FCM_SERVICE_ACCOUNT_KEY`
Firebase Admin SDK service account JSON. Used by push notification functions.

How to get it:
1. Go to [Firebase Console](https://console.firebase.google.com) → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Paste the entire JSON as a single line

### `BREVO_API_KEY`
Brevo (formerly Sendinblue) transactional email API key. Used by `verify-email` function for OTP codes.

How to get it:
1. Sign up at [brevo.com](https://www.brevo.com)
2. Go to Settings → API Keys → Generate a new API key

### `BREVO_FROM_EMAIL`
The "from" email address for verification emails (e.g., `noreply@yourdomain.com`).

### `GEMINI_API_KEY`
Google Gemini API key. Used by notification functions for AI-generated push notification copy. Optional — functions fall back to template messages if not set.

How to get it:
1. Go to [Google AI Studio](https://aistudio.google.com/apikey)
2. Create an API key

## Setting Secrets

**Local development:**
```bash
# Create .env.local in the supabase/ directory
npx supabase functions serve function-name --env-file .env.local
```

**Production:**
```bash
npx supabase secrets set \
  FCM_SERVICE_ACCOUNT_KEY='<json>' \
  BREVO_API_KEY='xkeysib-xxx' \
  BREVO_FROM_EMAIL='noreply@yourdomain.com' \
  GEMINI_API_KEY='AIza...'
```
