# Deploy supabaseSync Firebase function

This guide automates building and deploying the `supabaseSync` HTTP function used by the Supabase Edge Function `order-webhook` to sync payments/orders into Firestore.

Prerequisites
- Install Node.js 18+ and npm
- Install Firebase CLI and login: `npm install -g firebase-tools` and `firebase login`
- Ensure you have a Firebase project with Functions API enabled
- In this repo the Firebase functions live in `firebase_functions/` and the TypeScript sources in `firebase_functions/src/`

Steps (automated)

1. From the repository root, set environment variables and run the deploy script:

```bash
cd jengamate_new/firebase_functions
export FIREBASE_PROJECT="<your-firebase-project-id>"
export FIREBASE_SYNC_URL="https://<your-cloud-run-or-cloud-function>/supabaseSync"
export FIREBASE_SYNC_SECRET="<choose-a-secret>"
export SUPABASE_URL="https://ednovyqzrbaiyzlegbmy.supabase.co"
export SUPABASE_SERVICE_ROLE_KEY="<your-supabase-service-role-key>"

./DEPLOY_SUPABASE_SYNC.sh
```

2. Verify:

- Open the Firebase Console → Functions and confirm `supabaseSync` deployed and is active.
- Test with curl:

```bash
curl -X POST "$FIREBASE_SYNC_URL" \
  -H "Content-Type: application/json" \
  -H "x-sync-secret: $FIREBASE_SYNC_SECRET" \
  -d '{"resource":"ping","eventType":"ping","payload":{"test":true}}'
```

Troubleshooting
- If `firebase deploy` requires a token, create one with `firebase login:ci` and set `FIREBASE_TOKEN` env var.
- Ensure `firebase-tools` is up-to-date and you have permission to deploy to the project.

Security notes
- Keep `SUPABASE_SERVICE_ROLE_KEY` and `FIREBASE_SYNC_SECRET` secret. Do not commit them to source control.






