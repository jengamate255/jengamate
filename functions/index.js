const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Enhanced user creation with enterprise features
exports.createEnhancedUser = functions.auth.user().onCreate(async (user) => {
  const db = admin.firestore();
  const now = admin.firestore.FieldValue.serverTimestamp();
  
  const enhancedUser = {
    uid: user.uid,
    email: user.email,
    emailVerified: user.emailVerified,
    phoneNumber: user.phoneNumber || null,
    displayName: user.displayName || null,
    photo