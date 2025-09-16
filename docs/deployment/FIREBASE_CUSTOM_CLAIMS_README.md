# Firebase Custom Claims Setup (No Billing Required)

This guide provides **4 alternative approaches** to set up Firebase custom claims without using Firebase Functions (which requires billing).

## 🎯 **Why Custom Claims Are Needed**

Supabase requires users to have a `role: 'authenticated'` custom claim in their Firebase ID tokens to access protected resources and use Row Level Security (RLS).

## 📋 **Approach 1: Firebase Console Manual Setup (RECOMMENDED)**

### Step 1: Get Firebase Service Account Credentials
1. **Go to Firebase Console** → **Project Settings** → **Service Accounts**
2. **Generate Private Key** → Download the JSON file
3. **Save the JSON file** securely (don't commit to git)

### Step 2: Set Environment Variables
```bash
# Set these environment variables with values from your service account JSON
export FIREBASE_PROJECT_ID="your-project-id"
export FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY\n-----END PRIVATE KEY-----"
export FIREBASE_CLIENT_EMAIL="firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com"
```

### Step 3: Install Dependencies
```bash
npm install firebase-admin
```

### Step 4: Run the Custom Claims Script
```bash
# Set claims for ALL users
node set_custom_claims.js

# OR set claims for specific user
node set_custom_claims.js user@example.com
```

## 🛠️ **Approach 2: Firebase Console UI (Manual)**

### For New Users (Automatic):
1. **Go to Firebase Console** → **Authentication** → **Users**
2. **Select a user** → **Custom Claims** → **Add Claim**
3. **Add**: `role` = `authenticated`

### For Existing Users:
1. **Use the script above** to set claims for all users at once
2. **Or manually set claims** for each user in Firebase Console

## 🔄 **Approach 3: Client-Side Token Exchange**

If you prefer not to use custom claims at all, you can modify the Supabase integration:

### Update SupabaseService:
```dart
class SupabaseService {
  Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      // Remove accessToken - handle authentication manually
    );
  }

  // Add manual sign-in method
  Future<void> signInWithFirebaseToken(String firebaseToken) async {
    final response = await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.custom,
      idToken: firebaseToken,
    );
  }
}
```

### Update AuthService:
```dart
// In your auth flow, after Firebase sign-in:
final firebaseToken = await currentUser.getIdToken();
await SupabaseService.instance.signInWithFirebaseToken(firebaseToken);
```

## 🚀 **Approach 4: Supabase-Only Authentication (Simplest)**

Skip Firebase integration entirely and use Supabase's built-in authentication:

### Remove Firebase Dependencies:
```yaml
# Remove from pubspec.yaml:
# firebase_auth: ^4.20.0
# firebase_core: ^2.32.0
```

### Update AuthService to use Supabase Auth:
```dart
class AuthService {
  final supabase = Supabase.instance.client;

  Future<void> signUp(String email, String password) async {
    await supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Stream<AuthState> get authStateChanges =>
    supabase.auth.onAuthStateChange.map((event) => event.event);
}
```

## ✅ **Verification Steps**

After implementing any approach:

1. **Test Authentication**: Sign in to your Flutter app
2. **Check Supabase Auth**: Verify user appears in Supabase Dashboard → Authentication
3. **Test Protected Resources**: Try uploading payment proofs
4. **Check Logs**: Look for "Supabase auth successful" messages

## 📊 **Comparison Table**

| Approach | Billing Required | Setup Complexity | Maintenance |
|----------|------------------|------------------|-------------|
| Firebase Functions | ✅ Yes | Low | Automatic |
| Console Manual | ❌ No | Medium | Manual |
| Client-Side Exchange | ❌ No | Medium | Medium |
| Supabase-Only | ❌ No | Low | Low |

## 🎯 **Recommended Approach**

**For your use case**: **Approach 1 (Firebase Console + Script)**

**Why?**
- ✅ No billing required
- ✅ Works with your existing Firebase setup
- ✅ One-time setup for all users
- ✅ Reliable and secure

## 🔧 **Troubleshooting**

### Common Issues:

1. **"Invalid credentials"**
   - Check your Firebase service account JSON
   - Verify environment variables are set correctly

2. **"Permission denied"**
   - Ensure your Firebase account has admin privileges
   - Check Firebase project permissions

3. **Supabase auth still failing**
   - Verify custom claims are set: `role: 'authenticated'`
   - Check Supabase dashboard configuration
   - Ensure third-party auth is enabled

### Debug Commands:
```bash
# Check Firebase user claims
firebase auth:export users.json --project your-project-id

# Check Supabase auth status
# In your Flutter app, add debug prints
```

## 📞 **Support**

If you encounter issues:
1. **Check Firebase Console** → Functions/Authentication logs
2. **Verify Supabase Dashboard** → Authentication settings
3. **Test with the script** provided above

The integration should work perfectly once custom claims are set! 🎉
