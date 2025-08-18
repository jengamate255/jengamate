import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

const firestore = admin.firestore();

// Cloud Function to lock order fields after payment is confirmed
export const lockOrderAfterPayment = functions.firestore
    .document('orders/{orderId}')
    .onUpdate(async (change, context) => {
        const newOrder = change.after.data();
        const oldOrder = change.before.data();
        const orderId = context.params.orderId;

        // Check if the status has changed to 'fullyPaid'
        if (newOrder.status === 'fullyPaid' && oldOrder.status !== 'fullyPaid') {
            console.log(`Order ${orderId} is fully paid. Locking fields.`);

            // Update the order to set isLocked to true
            await firestore.collection('orders').doc(orderId).update({
                isLocked: true,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            console.log(`Order ${orderId} fields locked.`);
        }
    });