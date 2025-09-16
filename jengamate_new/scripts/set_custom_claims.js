#!/usr/bin/env node

/**
 * Script to manually set custom claims for Firebase users
 * Run this locally to avoid Firebase Functions billing
 *
 * Prerequisites:
 * 1. Install Firebase CLI: npm install -g firebase-tools
 * 2. Login: firebase login
 * 3. Install dependencies: npm install firebase-admin
 * 4. Set up Firebase Admin credentials (see README)
 *
 * Usage: node set_custom_claims.js
 */

const admin = require('firebase-admin');
const fs = require('fs');

// Use the service account JSON file directly
const serviceAccountPath = './jengamate-firebase-adminsdk-fbsvc-93da77a1af.json';

if (!fs.existsSync(serviceAccountPath)) {
  console.log('❌ Firebase service account JSON file not found:', serviceAccountPath);
  console.log('Make sure the file exists in the project root directory');
  process.exit(1);
}

// Read and parse the service account JSON file
const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));

// Initialize Firebase Admin with service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const auth = admin.auth();

async function setCustomClaimsForAllUsers() {
  console.log('🚀 Setting custom claims for all Firebase users...');

  let nextPageToken;
  let totalProcessed = 0;

  try {
    do {
      console.log('📄 Fetching users...');

      const listUsersResult = await auth.listUsers(100, nextPageToken);
      nextPageToken = listUsersResult.pageToken;

      console.log(`📋 Processing ${listUsersResult.users.length} users...`);

      // Process users in batches to avoid rate limits
      const promises = listUsersResult.users.map(async (userRecord) => {
        try {
          await auth.setCustomUserClaims(userRecord.uid, {
            role: 'authenticated'
          });

          console.log(`✅ Set claims for: ${userRecord.email || userRecord.uid}`);
          totalProcessed++;
        } catch (error) {
          console.error(`❌ Failed to set claims for ${userRecord.uid}:`, error.message);
        }
      });

      await Promise.all(promises);

    } while (nextPageToken);

    console.log(`\n🎉 Successfully processed ${totalProcessed} users!`);
    console.log('📝 All users now have the "authenticated" role for Supabase.');

  } catch (error) {
    console.error('❌ Error processing users:', error.message);
    console.log('\n🔧 Troubleshooting:');
    console.log('1. Check your Firebase Admin credentials');
    console.log('2. Ensure you have admin privileges on the Firebase project');
    console.log('3. Verify the environment variables are set correctly');
  }
}

// Function to set claims for a specific user
async function setCustomClaimsForUser(email) {
  console.log(`🚀 Setting custom claims for user: ${email}`);

  try {
    // Find user by email
    const userRecord = await auth.getUserByEmail(email);

    // Set custom claims
    await auth.setCustomUserClaims(userRecord.uid, {
      role: 'authenticated'
    });

    console.log(`✅ Successfully set custom claims for ${email}`);

  } catch (error) {
    console.error(`❌ Failed to set claims for ${email}:`, error.message);
  }
}

// Main execution
const args = process.argv.slice(2);

if (args.length > 0) {
  // Set claims for specific user
  const email = args[0];
  console.log(`Setting custom claims for user: ${email}`);
  setCustomClaimsForUser(email);
} else {
  // Set claims for all users
  console.log('Setting custom claims for ALL users...');
  console.log('⚠️  This will process all users in your Firebase project.');
  console.log('Press Ctrl+C to cancel, or wait 3 seconds to continue...');

  setTimeout(() => {
    setCustomClaimsForAllUsers();
  }, 3000);
}
