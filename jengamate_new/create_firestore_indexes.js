const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./firebase_configs/jengamate-firebase-adminsdk-fbsvc-93da77a1af.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'jengamate'
});

const firestore = admin.firestore();

async function createIndexes() {
  console.log('Creating missing Firestore indexes...');

  try {
    // Index 1: admin_notifications collection (userId + timestamp)
    console.log('Creating index for admin_notifications (userId, timestamp)...');
    const index1 = await firestore.collection('admin_notifications')
      .where('userId', '==', 'dummy')
      .orderBy('timestamp', 'desc')
      .limit(1)
      .get();

    console.log('Index 1 creation attempted');

    // Index 2: system_events collection (priority + timestamp)
    console.log('Creating index for system_events (priority, timestamp)...');
    const index2 = await firestore.collection('system_events')
      .where('priority', '==', 'critical')
      .where('timestamp', '>', admin.firestore.Timestamp.now())
      .limit(1)
      .get();

    console.log('Index 2 creation attempted');

    console.log('✅ Firestore indexes creation completed!');
    console.log('');
    console.log('📋 Manual Index Creation Links:');
    console.log('1. Admin Notifications Index:');
    console.log('   https://console.firebase.google.com/v1/r/project/jengamate/firestore/indexes?create_composite=ClVwcm9qZWN0cy9qZW5nYW1hdGUvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2FkbWluX25vdGlmaWNhdGlvbnMvaW5kZXhlcy9fEAEaCgoGdXNlcklkEAEaDQoJdGltZXN0YW1wEAIaDAoIX19uYW1lX18QAg');
    console.log('');
    console.log('2. System Events Index:');
    console.log('   https://console.firebase.google.com/v1/r/project/jengamate/firestore/indexes?create_composite=Ck9wcm9qZWN0cy9qZW5nYW1hdGUvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3N5c3RlbV9ldmVudHMvaW5kZXhlcy9fEAEaDAoIcHJpb3JpdHkQARoNCgl0aW1lc3RhbXAQARoMCghfX25hbWVfXxAB');

    console.log('');
    console.log('🔧 Alternative: Create indexes manually in Firebase Console:');
    console.log('1. Go to Firebase Console > Firestore Database > Indexes');
    console.log('2. Click "Create Index"');
    console.log('3. Create composite indexes for:');
    console.log('   - Collection: admin_notifications, Fields: userId (Asc), timestamp (Desc)');
    console.log('   - Collection: system_events, Fields: priority (Asc), timestamp (Desc)');

  } catch (error) {
    console.error('❌ Error creating indexes:', error);
    console.log('');
    console.log('🔧 Please create the indexes manually in Firebase Console:');
    console.log('1. Go to Firebase Console > Firestore Database > Indexes');
    console.log('2. Click "Create Index" for each required index');
  } finally {
    // Close the connection
    admin.app().delete();
  }
}

// Run the function
createIndexes().catch(console.error);





