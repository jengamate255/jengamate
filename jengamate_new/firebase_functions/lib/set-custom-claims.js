"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onUserRoleChange = void 0;
const admin = require("firebase-admin");
const firestore_1 = require("firebase-functions/v2/firestore");
admin.initializeApp();
exports.onUserRoleChange = (0, firestore_1.onDocumentUpdated)('users/{userId}', async (event) => {
    var _a, _b;
    const { data, params } = event;
    if (!data || !data.before || !data.after)
        return;
    const newRole = (_a = data.after.data()) === null || _a === void 0 ? void 0 : _a.role;
    const oldRole = (_b = data.before.data()) === null || _b === void 0 ? void 0 : _b.role;
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
    }
    catch (error) {
        console.error(`Error setting custom claim for user ${userId}:`, error);
        return null;
    }
});
//# sourceMappingURL=set-custom-claims.js.map