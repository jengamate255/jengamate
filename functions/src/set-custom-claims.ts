import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const onUserRoleChange = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const newRole = change.after.data().role;
    const oldRole = change.before.data().role;
    const userId = context.params.userId;

    if (newRole === oldRole) {
      console.log(`Role for user ${userId} has not changed.`);
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
  });