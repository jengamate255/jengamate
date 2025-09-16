import * as admin from "firebase-admin";
import { onDocumentUpdated, Change, FirestoreEvent, QueryDocumentSnapshot } from 'firebase-functions/v2/firestore';

admin.initializeApp();

export const onUserRoleChange = onDocumentUpdated(
  'users/{userId}',
  async (event: FirestoreEvent<Change<QueryDocumentSnapshot> | undefined, { userId: string }>) => {
    const { data, params } = event;
    if (!data || !data.before || !data.after) return;

    const newRole = data.after.data()?.role;
    const oldRole = data.before.data()?.role;
    const userId = params.userId;

    if (newRole === oldRole) {
      console.log(`Role for user ${userId} has not changed.`);
      return null;
    }

    if (!newRole) {
      console.log(`New role for user ${userId} is undefined. Skipping custom claims update.`);
      return null;
    }

    try {
      await admin.auth().setCustomUserClaims(userId, { role: newRole });
      console.log(`Successfully set custom claim for user ${userId} to role: ${newRole}`);
      return null;
    } catch (error) {
      console.error(`Error setting custom claim for user ${userId}:`, error);
      return null;
    }
  }
);