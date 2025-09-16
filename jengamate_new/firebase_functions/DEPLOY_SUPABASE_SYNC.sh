#!/usr/bin/env bash
set -euo pipefail

# Deploy helper for the supabaseSync Firebase function
# Usage:
#   FIREBASE_PROJECT=<your-firebase-project-id> \ 
#   FIREBASE_SYNC_URL=<https://.../supabaseSync> \
#   FIREBASE_SYNC_SECRET=<secret> \
#   SUPABASE_URL=<https://your-supabase> \
#   SUPABASE_SERVICE_ROLE_KEY=<service-role-key> \
#   ./DEPLOY_SUPABASE_SYNC.sh

if [ -z "${FIREBASE_PROJECT:-}" ]; then
  echo "FIREBASE_PROJECT is not set. Export your Firebase project id as FIREBASE_PROJECT." >&2
  exit 1
fi

if [ -z "${FIREBASE_SYNC_URL:-}" ]; then
  echo "FIREBASE_SYNC_URL is not set. Export the URL of your supabaseSync HTTP function." >&2
  exit 1
fi

if [ -z "${FIREBASE_SYNC_SECRET:-}" ]; then
  echo "FIREBASE_SYNC_SECRET is not set. Export a shared secret as FIREBASE_SYNC_SECRET." >&2
  exit 1
fi

if [ -z "${SUPABASE_URL:-}" ]; then
  echo "SUPABASE_URL is not set. Export your Supabase project URL as SUPABASE_URL." >&2
  exit 1
fi

if [ -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]; then
  echo "SUPABASE_SERVICE_ROLE_KEY is not set. Export your Supabase service role key as SUPABASE_SERVICE_ROLE_KEY." >&2
  exit 1
fi

echo "Setting Firebase functions config..."
firebase functions:config:set \
  supabase.url="$SUPABASE_URL" \
  supabase.service_role_key="$SUPABASE_SERVICE_ROLE_KEY" \
  sync.firebase_url="$FIREBASE_SYNC_URL" \
  sync.secret="$FIREBASE_SYNC_SECRET" \
  --project "$FIREBASE_PROJECT"

echo "Building TypeScript functions..."
npm run build --prefix ./ || true

echo "Deploying only supabaseSync function to Firebase project: $FIREBASE_PROJECT"
firebase deploy --only functions:supabaseSync --project "$FIREBASE_PROJECT"

echo "Deployment finished. Verify the function on Firebase console and test by POSTing to $FIREBASE_SYNC_URL with header x-sync-secret: $FIREBASE_SYNC_SECRET"






