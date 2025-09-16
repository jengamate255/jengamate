const {onCall} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore} = require("firebase-admin/firestore");

// Initialize Firebase Admin
initializeApp();

// Function to set custom claims for new users
const {beforeUserCreated, beforeUserSignedIn} = require("firebase-functions/v2/identity");

exports.beforeUserCreated = beforeUserCreated((event) => {
  return {
    customClaims: {
      role: 'authenticated',
    },
  };
});

exports.beforeUserSignedIn = beforeUserSignedIn((event) => {
  return {
    customClaims: {
      role: 'authenticated',
    },
  };
});

// Alternative: Manual function to set custom claims for existing users
exports.setCustomClaims = onCall(async (data, context) => {
  // Only allow authenticated users to call this function
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'The function must be called while authenticated.'
    );
  }

  const uid = context.auth.uid;
  const role = 'authenticated';

  try {
    await getAuth().setCustomUserClaims(uid, { role });
    return { message: `Custom claims set for user ${uid}` };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Function to set custom claims for all existing users
exports.setAllUsersCustomClaims = onCall(async (data, context) => {
  // This should be called from Firebase Console or admin interface
  // In production, add proper authentication checks

  const auth = getAuth();
  let nextPageToken;

  try {
    let usersProcessed = 0;

    do {
      const listUsersResult = await auth.listUsers(1000, nextPageToken);
      nextPageToken = listUsersResult.pageToken;

      const promises = listUsersResult.users.map(async (userRecord) => {
        try {
          await auth.setCustomUserClaims(userRecord.uid, { role: 'authenticated' });
          console.log(`Set custom claims for user: ${userRecord.uid}`);
          usersProcessed++;
        } catch (error) {
          console.error(`Failed to set claims for user ${userRecord.uid}:`, error);
        }
      });

      await Promise.all(promises);

    } while (nextPageToken);

    return {
      message: `Processed ${usersProcessed} users`,
      success: true
    };

  } catch (error) {
    console.error('Error processing users:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});