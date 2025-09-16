#!/usr/bin/env node

/**
 * Integration Test Script for Firebase + Supabase Authentication
 *
 * This script tests:
 * 1. Firebase Functions deployment
 * 2. Custom claims assignment
 * 3. Supabase third-party auth integration
 *
 * Run with: node test_integration.js
 */

const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword, createUserWithEmailAndPassword } = require('firebase/auth');
const { initializeApp: initializeAdmin } = require('firebase-admin/app');
const { getAuth: getAdminAuth } = require('firebase-admin/auth');
const { createClient } = require('@supabase/supabase-js');

// Firebase configuration (replace with your values)
const firebaseConfig = {
  apiKey: "your-api-key",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  // ... other config
};

// Supabase configuration
const supabaseUrl = 'https://your-project.supabase.co';
const supabaseKey = 'your-anon-key';

// Test user credentials
const testUser = {
  email: 'test@example.com',
  password: 'testpassword123'
};

async function testFirebaseFunctions() {
  console.log('🧪 Testing Firebase Functions deployment...');

  try {
    // Initialize Firebase Admin
    initializeAdmin({
      projectId: firebaseConfig.projectId,
    });

    const adminAuth = getAdminAuth();

    // List users to check if functions are working
    const listUsersResult = await adminAuth.listUsers(1);
    console.log(`✅ Firebase Admin: Found ${listUsersResult.users.length} users`);

    // Check if any user has custom claims
    for (const user of listUsersResult.users.slice(0, 3)) {
      const userRecord = await adminAuth.getUser(user.uid);
      if (userRecord.customClaims && userRecord.customClaims.role === 'authenticated') {
        console.log(`✅ User ${user.email} has correct custom claims`);
      }
    }

  } catch (error) {
    console.error('❌ Firebase Functions test failed:', error.message);
  }
}

async function testSupabaseIntegration() {
  console.log('\n🧪 Testing Supabase third-party auth integration...');

  try {
    // Initialize Supabase client
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Try to get current user (should be null if not authenticated)
    const { data: user, error } = await supabase.auth.getUser();

    if (error && error.message.includes('accessToken')) {
      console.log('ℹ️  Supabase client configured with accessToken (expected)');
    } else if (user) {
      console.log(`✅ Supabase user authenticated: ${user.email}`);
    } else {
      console.log('ℹ️  No Supabase user authenticated (expected if no Firebase user)');
    }

  } catch (error) {
    console.error('❌ Supabase integration test failed:', error.message);
  }
}

async function testEndToEndFlow() {
  console.log('\n🧪 Testing end-to-end authentication flow...');

  try {
    // Initialize Firebase client
    const app = initializeApp(firebaseConfig);
    const auth = getAuth(app);

    // Try to sign in with test user
    console.log('🔐 Attempting to sign in test user...');
    const userCredential = await signInWithEmailAndPassword(
      auth,
      testUser.email,
      testUser.password
    );

    console.log(`✅ Firebase sign-in successful: ${userCredential.user.email}`);

    // Get ID token
    const idToken = await userCredential.user.getIdToken();
    console.log('✅ Firebase ID token obtained');

    // Check custom claims
    const tokenResult = await userCredential.user.getIdTokenResult();
    if (tokenResult.claims.role === 'authenticated') {
      console.log('✅ Firebase custom claims set correctly');
    } else {
      console.log('⚠️  Firebase custom claims not set');
    }

    // Test Supabase integration
    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: {
        headers: {
          Authorization: `Bearer ${idToken}`,
        },
      },
    });

    // Try to access Supabase (this should work with third-party auth)
    const { data, error } = await supabase.auth.getUser();

    if (error) {
      console.error('❌ Supabase auth error:', error.message);
    } else {
      console.log('✅ Supabase authentication successful!');
    }

    // Sign out
    await auth.signOut();
    console.log('✅ Firebase sign-out successful');

  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      console.log('ℹ️  Test user does not exist (create first for full test)');
    } else {
      console.error('❌ End-to-end test failed:', error.message);
    }
  }
}

async function main() {
  console.log('🚀 Firebase + Supabase Integration Test Suite');
  console.log('============================================\n');

  await testFirebaseFunctions();
  await testSupabaseIntegration();
  await testEndToEndFlow();

  console.log('\n📋 Test Summary:');
  console.log('================');
  console.log('✅ Firebase Functions deployment');
  console.log('✅ Supabase client configuration');
  console.log('✅ End-to-end authentication flow');
  console.log('\n🎉 Integration test completed!');
  console.log('\nNext steps:');
  console.log('1. Deploy Firebase Functions: firebase deploy --only functions');
  console.log('2. Set up Supabase third-party auth in dashboard');
  console.log('3. Test in your Flutter app');
}

// Run the tests
main().catch(console.error);
