// JavaScript to add user documents to Firestore for existing Firebase users
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./firebase_service_account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'jengamate'
});

const db = admin.firestore();

// User data for existing Firebase users
const usersData = {
  'SHSppdgKd8NXWUZ8KMLxnW0raik1': {
    uid: 'SHSppdgKd8NXWUZ8KMLxnW0raik1',
    email: 'eatorker@gmail.com',
    role: 'admin',
    displayName: 'Admin User',
    phoneNumber: null,
    company: 'JengaMate Admin',
    isApproved: true,
    createdAt: admin.firestore.Timestamp.fromMillis(1751548797947),
    lastLoginAt: admin.firestore.Timestamp.fromMillis(1751548797947)
  }
};

async function addUsersToFirestore() {
  const promises = [];

  for (const [userId, userData] of Object.entries(usersData)) {
    const promise = db.collection('users').doc(userId).set(userData);
    promises.push(promise);
    console.log(`Adding user: ${userData.email} with role: ${userData.role}`);
  }

  try {
    await Promise.all(promises);
    console.log('✅ Successfully added all user documents to Firestore!');
  } catch (error) {
    console.error('❌ Error adding user documents:', error);
  }

  process.exit();
}

addUsersToFirestore();
