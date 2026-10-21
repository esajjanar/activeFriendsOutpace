# Urgent Security Remediation Guide

## ⚠️ CRITICAL: DO NOT PUBLISH REPOSITORY WITHOUT COMPLETING THESE STEPS

Your Active Friends Outpace app repository has **2 critical security issues** that MUST be fixed before going open-source.

---

## 🔴 Critical Issue #1: Firebase API Keys Exposed

**Status:** COMPROMISED (If repo becomes public)
**Impact:** Full access to Firebase backend by anyone with the keys

### What's Exposed?
```
Android Firebase:
  - API Key: AIzaSyAqQ0Nwi6eHcU2h-H6DsI5exB76nYtnVsE
  - Project: outpace-ab523

iOS Firebase:
  - API Key: AIzaSyBQ8RNcLyJ_AHmR0yOEk0TNQVuhJsfPaP4
  - Project: outpace-ab523
```

### Immediate Actions (Today)

#### Step 1: Revoke Compromised Keys (Google Cloud Console)
```
1. Go to: https://console.firebase.google.com/
2. Select project: "outpace-ab523"
3. Go to: Settings → Service Accounts
4. Find and revoke the exposed API keys
5. Alternative: Project Settings → General → Delete & recreate credentials
```

#### Step 2: Check Firebase Audit Logs
```
1. In Firebase Console: Settings → Manage API Keys
2. Review access logs for unauthorized activity
3. Look for suspicious Firestore/Storage access
4. Review FCM message sending history
```

#### Step 3: Update .gitignore (Right Now!)
```bash
# Edit app/.gitignore and add:
# Generated Firebase configuration - NEVER commit actual credentials
lib/firebase_options.dart
```

#### Step 4: Regenerate Firebase Configuration
```bash
cd /Users/I589392/mygit/activeFriendsOutpace/app/

# Run FlutterFire CLI to generate new config
dart pub global activate flutterfire_cli
flutterfire configure

# This will create a new lib/firebase_options.dart with new keys
```

#### Step 5: Clean Git History (Most Important!)
```bash
# Option A: Using git-filter-branch (simpler)
cd /Users/I589392/mygit/activeFriendsOutpace/

git filter-branch -f --tree-filter 'rm -f app/lib/firebase_options.dart' -- --all

# Option B: Using BFG (faster for large repos - RECOMMENDED)
# Download from: https://rtyley.github.io/bfg-repo-cleaner/

java -jar bfg.jar --delete-files firebase_options.dart

# Option C: Using git-filter-repo (modern, recommended)
pip install git-filter-repo

git filter-repo --path app/lib/firebase_options.dart --invert-paths
```

#### Step 6: Force Push (Use with Caution!)
```bash
# WARNING: This rewrites history - ensure all team members pull fresh
git push origin --force-with-lease --all
git push origin --force-with-lease --tags
```

---

## 🔴 Critical Issue #2: firebase_options.dart Not in .gitignore

**Status:** OPEN (Allows accidental commits of credentials)

### What to Do:

1. **Edit app/.gitignore:**
```bash
nano /Users/I589392/mygit/activeFriendsOutpace/app/.gitignore
```

2. **Add these lines after "# Flutter/Dart/Pub related" section:**
```
# Generated Firebase configuration - NEVER commit actual credentials
lib/firebase_options.dart
```

3. **Verify the change:**
```bash
cd /Users/I589392/mygit/activeFriendsOutpace/app
git check-ignore -v lib/firebase_options.dart
# Should output: app/.gitignore:XX:lib/firebase_options.dart
```

4. **Commit the .gitignore update:**
```bash
git add .gitignore
git commit -m "chore: add firebase_options.dart to gitignore"
git push origin main
```

---

## 📋 Complete Remediation Checklist

### Phase 1: Immediate (Do This TODAY)
- [ ] Revoke both Firebase API keys in Google Cloud Console
- [ ] Check Firebase Audit Logs for unauthorized access
- [ ] Update .gitignore to exclude firebase_options.dart
- [ ] Verify .gitignore change and commit
- [ ] Run flutterfire configure to generate new credentials
- [ ] Update your local firebase_options.dart file

### Phase 2: History Cleanup (Do This BEFORE Public Release)
- [ ] Back up current code locally: `git clone . backup-before-cleanup`
- [ ] Clean Git history using one of the methods above
- [ ] Force push all branches and tags
- [ ] Verify sensitive file is removed: `git log --all -- app/lib/firebase_options.dart` (should be empty)
- [ ] Alert team members to re-clone repository
- [ ] Delete old backup clone after verification

### Phase 3: Pre-Release (Before Going Public)
- [ ] Create SECURITY.md with vulnerability reporting policy
- [ ] Create CONTRIBUTING.md with environment setup instructions
- [ ] Add pre-commit hook to prevent future credential commits
- [ ] Implement GitHub Secret Scanning (if using GitHub)
- [ ] Review all other environment-specific files in .gitignore
- [ ] Run final security scan to verify no credentials remain

### Phase 4: Post-Release (After Going Public)
- [ ] Monitor for misuse of exposed keys
- [ ] Set up GitHub secret scanning alerts
- [ ] Implement automated security scanning in CI/CD
- [ ] Regular rotation of sensitive credentials
- [ ] Document security best practices for contributors

---

## ✅ Verification Steps

### Confirm Keys Are Removed from History:
```bash
cd /Users/I589392/mygit/activeFriendsOutpace/

# Should return NO results
git log -p --all | grep "AIzaSyAqQ0Nwi6eHcU2h-H6DsI5exB76nYtnVsE"
git log -p --all | grep "AIzaSyBQ8RNcLyJ_AHmR0yOEk0TNQVuhJsfPaP4"
```

### Confirm .gitignore Is Configured:
```bash
cd app
git check-ignore lib/firebase_options.dart && echo "✓ File is properly ignored"
```

### Confirm New Credentials Work:
```bash
cd app
flutter pub get
flutter run  # Test on device/emulator to verify Firebase works
```

---

## 🔒 Security Best Practices for Future Development

### 1. Never Commit Credentials
```dart
// ❌ WRONG - Don't do this
const apiKey = "AIza...";  

// ✅ RIGHT - Use environment variables
const apiKey = String.fromEnvironment('FIREBASE_API_KEY');

// ✅ ALSO RIGHT - Like your Supabase config
static const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
```

### 2. Add Pre-commit Hook
```bash
# Create: app/.git/hooks/pre-commit
#!/bin/bash
if git diff --cached | grep -E 'AIza|sk_|pk_|apiKey.*=.*["\']'; then
  echo "ERROR: Potential secret found in staged files!"
  echo "Do not commit API keys or secrets."
  exit 1
fi
exit 0

chmod +x app/.git/hooks/pre-commit
```

### 3. Use Environment Variables
```bash
# When building/running:
flutter run \
  --dart-define=FIREBASE_API_KEY=your_key \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your_key
```

### 4. Document Setup Instructions
Create `CONTRIBUTING.md`:
```markdown
## Environment Setup

Each developer must generate their own Firebase credentials:

1. Install FlutterFire CLI:
   dart pub global activate flutterfire_cli

2. Configure Firebase:
   cd app
   flutterfire configure

3. Set environment variables:
   export SUPABASE_URL=your_url
   export SUPABASE_PUBLISHABLE_KEY=your_key

4. Run the app:
   flutter run
```

---

## 📞 Need Help?

### Tools for Secret Detection:
- **detect-secrets** (Python): `pip install detect-secrets`
- **git-secrets** (Bash): https://github.com/awslabs/git-secrets
- **TruffleHog** (Go): https://github.com/trufflesecurity/truffleHog
- **GitHub Secret Scanning**: Built-in for GitHub Enterprise

### Resources:
- Firebase Security: https://firebase.google.com/docs/projects/api/authentication/best-practices
- Dart Best Practices: https://dart.dev/guides/libraries/private-files
- OWASP Secrets Management: https://owasp.org/www-community/Sensitive_Data_Exposure

---

## ⏰ Timeline Recommendation

**Week 1:**
- Day 1-2: Complete all Phase 1 and 2 steps
- Day 3: Verify and test
- Day 4-5: Create security documentation

**Week 2:**
- Day 1-2: Implement pre-commit hooks
- Day 3-5: Final review and testing

**Week 3:**
- Ready for public release

---

## Questions?

If you're unsure about any step:
1. Re-read this guide
2. Verify against the automated scan report
3. Test locally before pushing
4. When in doubt, ask for code review

**DO NOT publish until all items are completed.**

Good luck with your open-source launch! 🚀
