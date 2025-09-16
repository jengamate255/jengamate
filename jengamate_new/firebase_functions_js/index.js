/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {createClient} = require("@supabase/supabase-js");
const cors = require("cors")({origin: true});

admin.initializeApp();

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
// setGlobalOptions({ maxInstances: 10 }); // This line was removed as per the edit hint.

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.exchangeFirebaseTokenForSupabaseToken = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    const {firebaseIdToken} = req.body;

    if (!firebaseIdToken) {
      return res.status(400).send("Firebase ID token is required.");
    }

    try {
      // 1. Verify the Firebase ID token
      const decodedToken = await admin.auth().verifyIdToken(firebaseIdToken);
      const uid = decodedToken.uid;

      // 2. Initialize Supabase client with the Service Role Key
      const supabaseUrl = functions.config().supabase.url;
      const supabaseServiceRoleKey = functions.config().supabase.service_role_key;

      if (!supabaseUrl || !supabaseServiceRoleKey) {
        console.error(
          "Supabase URL or Service Role Key not configured in Firebase environment variables."
        );
        return res.status(500).send("Server configuration error.");
      }

      const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);

      // 3. Generate a custom Supabase JWT
      // This approach uses the admin client to sign in and get a session,
      // which then contains the access token (JWT)
      const {data, error} = await supabaseAdmin.auth.signInWithIdToken({
        provider: "custom_firebase", // A custom provider name to identify this flow
        idToken: uid, // Pass the Firebase UID as the idToken for custom provider
      });

      if (error) {
        console.error("Error creating Supabase session:", error);
        return res.status(500).send("Error exchanging token: " + error.message);
      }

      if (!data || !data.session || !data.session.access_token) {
        console.error("Supabase session or access token not found:", data);
        return res.status(500).send("Supabase session or access token not found.");
      }

      return res.status(200).json({supabaseAccessToken: data.session.access_token});
    } catch (error) {
      console.error("Error in exchangeFirebaseTokenForSupabaseToken:", error);
      if (error.code === "auth/id-token-expired") {
        return res.status(401).send("Firebase ID token expired.");
      }
      return res.status(500).send("Internal server error: " + error.message);
    }
  });
});
