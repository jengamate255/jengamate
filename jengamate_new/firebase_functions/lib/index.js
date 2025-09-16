"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.supabaseSync = exports.lockOrderAfterPayment = void 0;
const admin = require("firebase-admin");
const supabase_js_1 = require("@supabase/supabase-js"); // Import Supabase client
const firestore_1 = require("firebase-functions/v2/firestore"); // Import v2 firestore functions and types
const https_1 = require("firebase-functions/v2/https"); // Import v2 http functions and types
admin.initializeApp();
const firestore = admin.firestore();
// Initialize Supabase client
const supabaseAdmin = (0, supabase_js_1.createClient)("https://ednovyqzrbaiyzlegbmy.supabase.co", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVkbm92eXF6cmJhaXl6bGVnYm15Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTE1NDg3NCwiZXhwIjoyMDcwMzc5Njc0fQ.piyUYeRXzwW1Wk0nSS76Y9eOm0_Frh9h7eFD81708XM");
// Cloud Function to lock order fields after payment is confirmed
exports.lockOrderAfterPayment = (0, firestore_1.onDocumentUpdated)('orders/{orderId}', async (event) => {
    const { data, params } = event;
    if (!data || !data.before || !data.after)
        return; // No data, nothing to do
    const orderId = params.orderId;
    const orderBefore = data.before.data();
    const orderAfter = data.after.data();
    if (!orderBefore || !orderAfter)
        return; // Should not happen for onUpdate, but for safety
    // Check if the status has changed to 'fullyPaid'
    if (orderAfter.status === 'fullyPaid' && orderBefore.status !== 'fullyPaid') {
        console.log(`Order ${orderId} is fully paid. Locking fields.`);
        // Logic to lock fields... (not provided in snippet, assuming it exists or will be added)
    }
});
// HTTP endpoint to receive Supabase events and idempotently sync to Firestore
exports.supabaseSync = (0, https_1.onRequest)(async (req, res) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o;
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
            const data = {
                orderId: (_a = payload.order_id) !== null && _a !== void 0 ? _a : payload.orderId,
                userId: (_b = payload.user_id) !== null && _b !== void 0 ? _b : payload.userId,
                amount: ((_c = payload.amount) !== null && _c !== void 0 ? _c : 0),
                status: (_e = (_d = payload.status) !== null && _d !== void 0 ? _d : payload.state) !== null && _e !== void 0 ? _e : 'unknown',
                paymentMethod: (_f = payload.payment_method) !== null && _f !== void 0 ? _f : payload.paymentMethod,
                transactionId: (_g = payload.transaction_id) !== null && _g !== void 0 ? _g : payload.transactionId,
                paymentProofUrl: (_h = payload.payment_proof_url) !== null && _h !== void 0 ? _h : payload.paymentProofUrl,
                createdAt: payload.created_at ? new Date(payload.created_at) : admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: payload.updated_at ? new Date(payload.updated_at) : admin.firestore.FieldValue.serverTimestamp(),
                metadata: (_j = payload.metadata) !== null && _j !== void 0 ? _j : null,
                autoApproved: (_k = payload.auto_approved) !== null && _k !== void 0 ? _k : false,
            };
            await docRef.set(data, { merge: true });
            if (payload.order_id && payload.amount != null) {
                const orderRef = firestore.collection('orders').doc(payload.order_id);
                await firestore.runTransaction(async (tx) => {
                    var _a, _b;
                    const snap = await tx.get(orderRef);
                    const current = (snap.exists && ((_b = (_a = snap.data()) === null || _a === void 0 ? void 0 : _a.amountPaid) !== null && _b !== void 0 ? _b : 0));
                    const newAmount = (current) + payload.amount;
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
            const data = {
                totalAmount: (_l = payload.total_amount) !== null && _l !== void 0 ? _l : payload.totalAmount,
                status: payload.status,
                orderNumber: (_m = payload.order_number) !== null && _m !== void 0 ? _m : payload.orderNumber,
                updatedAt: payload.updated_at ? new Date(payload.updated_at) : admin.firestore.FieldValue.serverTimestamp(),
                currency: (_o = payload.currency) !== null && _o !== void 0 ? _o : 'TSh',
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
    }
    catch (e) { // Explicitly type 'e' as any to resolve TS18046
        console.error('supabaseSync error', e);
        res.status(500).send({ error: e.message });
        return; // Explicit return for error path
    }
});
//# sourceMappingURL=index.js.map