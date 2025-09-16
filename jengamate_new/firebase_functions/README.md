# Firebase Functions Setup for Supabase Integration

This directory contains Firebase Functions that automatically set custom claims for Supabase authentication.

## 🚀 Quick Setup

### 1. Install Firebase CLI (if not already installed)
```bash
npm install -g firebase-tools
```

### 2. Login to Firebase
```bash
firebase login
```

### 3. Initialize Firebase Functions (if not already done)
```bash
cd firebase-functions
firebase init functions
```
- Select your Firebase project
- Choose **TypeScript** or **JavaScript** (we'll use JavaScript)
- Choose **ESLint** (optional)
- Install dependencies: **Yes**

### 4. Deploy the Functions
```bash
firebase deploy --only functions
```

## 📋 What These Functions Do

### `beforeUserCreated` & `beforeUserSignedIn`
- Automatically assigns `role: 'authenticated'` custom claim to all users
- Runs when users sign up or sign in
- Required for Supabase Row Level Security (RLS)

### `setAllUsersCustomClaims`
- Manually sets custom claims for existing users
- Useful if you have users before setting up these functions

### `setCustomClaims`
- Allows authenticated users to set custom claims (for testing)

## 🔧 Manual Setup (Alternative)

If you prefer to set custom claims manually for existing users, run this script:

```javascript
// Run this in Firebase Console > Functions > Logs
const admin = require('firebase-admin');
admin.initializeApp();

async function setAllUsersClaims() {
  const auth = admin.auth();
  let nextPageToken;

  do {
    const result = await auth.listUsers(1000, nextPageToken);
    nextPageToken = result.pageToken;

    const promises = result.users.map(user =>
      auth.setCustomUserClaims(user.uid, { role: 'authenticated' })
    );

    await Promise.all(promises);
  } while (nextPageToken);

  console.log('All users updated with custom claims');
}

setAllUsersClaims();
```

## ✅ Verification

After deployment, you can verify the functions work by:

1. **Check Firebase Console** → Functions to see deployed functions
2. **Test with new user**: Sign up a new user and check their custom claims
3. **Check logs**: View function execution logs in Firebase Console

## 🔄 Next Steps

Once Firebase Functions are deployed:

1. **Add Firebase Auth integration in Supabase Dashboard**
2. **Test the integration** using the Auth Test screen (`/auth-test`)
3. **Verify payment proof uploads work** (original error should be fixed)

## 📝 Notes

- Functions use **Identity Platform triggers** which require Firebase Authentication with Identity Platform
- Custom claims appear in Firebase ID tokens and are used by Supabase for authorization
- The `role: 'authenticated'` claim tells Supabase to assign the `authenticated` Postgres role
