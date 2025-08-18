"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onUserRoleChange = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
exports.onUserRoleChange = functions.firestore
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
    }
    catch (error) {
        console.error(`Error setting custom claim for user ${userId}:`, error);
        return null;
    }
});
//# sourceMappingURL=set-custom-claims.js.map