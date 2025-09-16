import * as admin from 'firebase-admin';
import { createClient } from '@supabase/supabase-js'; // Import Supabase client
import { onDocumentUpdated, Change, FirestoreEvent, QueryDocumentSnapshot } from 'firebase-functions/v2/firestore'; // Import v2 firestore functions and types
import { onRequest, Request } from 'firebase-functions/v2/https'; // Import v2 http functions and types

admin.initializeApp();

const firestore = admin.firestore();

// Initialize Supabase client
const supabaseAdmin = createClient(
  "https://ednovyqzrbaiyzlegbmy.supabase.co",
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVkbm92eXF6cmJhaXl6bGVnYm15Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTE1NDg3NCwiZXhwIjoyMDcwMzc5Njc0fQ.piyUYeRXzwW1Wk0nSS76Y9eOm0_Frh9h7eFD81708XM"
);

// Cloud Function to lock order fields after payment is confirmed
export const lockOrderAfterPayment = onDocumentUpdated(
  'orders/{orderId}',
  async (event: FirestoreEvent<Change<QueryDocumentSnapshot> | undefined, { orderId: string }>) => {
    const { data, params } = event;
    if (!data || !data.before || !data.after) return; // No data, nothing to do

    const orderId = params.orderId;
    const orderBefore = data.before.data();
    const orderAfter = data.after.data();

    if (!orderBefore || !orderAfter) return; // Should not happen for onUpdate, but for safety

    // Check if the status has changed to 'fullyPaid'
    if (orderAfter.status === 'fullyPaid' && orderBefore.status !== 'fullyPaid') {
      console.log(`Order ${orderId} is fully paid. Locking fields.`);
      // Logic to lock fields... (not provided in snippet, assuming it exists or will be added)
    }
  }
);

// HTTP endpoint to receive Supabase events and idempotently sync to Firestore
export const supabaseSync = onRequest(async (req: Request, res) => {
  try {
    const secret = req.get('x-sync-secret') || req.query.secret;
    if (!secret || secret !== process.env.SUPABASE_SYNC_SECRET) {
      res.status(401).send('Unauthorized');
      return; // Explicit return to ensure all paths return
    }

    const body = req.body || {};
    const resource = body.resource; // 'order' or 'payment'
    const eventType = body.eventType; // e.g., 'created'|'updated'
    const payload = body.payload || {};

    if (!resource || !eventType || !payload) {
      res.status(400).send('Missing required fields');
      return; // Explicit return
    }

    if (resource === 'payment') {
      const paymentId = payload.id;
      if (!paymentId) {
        res.status(400).send('Missing payment id');
        return; // Explicit return
      }

      const docRef = firestore.collection('payments').doc(paymentId);
      const data: any = {
        orderId: payload.order_id ?? payload.orderId,
        userId: payload.user_id ?? payload.userId,
        amount: (payload.amount ?? 0),
        status: payload.status ?? payload.state ?? 'unknown',
        paymentMethod: payload.payment_method ?? payload.paymentMethod,
        transactionId: payload.transaction_id ?? payload.transactionId,
        paymentProofUrl: payload.payment_proof_url ?? payload.paymentProofUrl,
        createdAt: payload.created_at ? new Date(payload.created_at) : admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: payload.updated_at ? new Date(payload.updated_at) : admin.firestore.FieldValue.serverTimestamp(),
        metadata: payload.metadata ?? null,
        autoApproved: payload.auto_approved ?? false,
      };

      await docRef.set(data, { merge: true });

      if (payload.order_id && payload.amount != null) {
        const orderRef = firestore.collection('orders').doc(payload.order_id);
        await firestore.runTransaction(async (tx) => {
          const snap = await tx.get(orderRef);
          const current = (snap.exists && (snap.data()?.amountPaid ?? 0)) as number;
          const newAmount = (current) + (payload.amount as number);
          tx.set(orderRef, { amountPaid: newAmount, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
        });
      }

      res.status(200).send({ success: true });
      return; // Explicit return
    }

    if (resource === 'order') {
      const orderId = payload.id;
      if (!orderId) {
        res.status(400).send('Missing order id');
        return; // Explicit return
      }

      const data: any = {
        totalAmount: payload.total_amount ?? payload.totalAmount,
        status: payload.status,
        orderNumber: payload.order_number ?? payload.orderNumber,
        updatedAt: payload.updated_at ? new Date(payload.updated_at) : admin.firestore.FieldValue.serverTimestamp(),
        currency: payload.currency ?? 'TSh',
      };

      if (payload.amount_paid != null) {
        data.amountPaid = payload.amount_paid;
      }

      await firestore.collection('orders').doc(orderId).set(data, { merge: true });

      // Also update Supabase with the Firestore orderId as external_id
      await supabaseAdmin.from('orders').update({ external_id: orderId }).eq('id', payload.id);

      res.status(200).send({ success: true });
      return; // Explicit return
    }

    res.status(400).send('Unsupported resource');
    return; // Explicit return for unsupported resource
  } catch (e: any) { // Explicitly type 'e' as any to resolve TS18046
    console.error('supabaseSync error', e);
    res.status(500).send({ error: e.message });
    return; // Explicit return for error path
  }
});