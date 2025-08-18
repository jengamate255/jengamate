/*
  Import Firebase auth users into Supabase.
  Notes:
  - Firebase password hashes are not compatible; we cannot migrate passwords.
  - This script creates users via Supabase Admin API and prints password reset links.

  Requirements:
  - Node 18+
  - env vars: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
  - input file: path to Firebase auth_export.json (default: ../../auth_export.json)

  Usage:
    node scripts/supabase/import_users.js [path/to/auth_export.json]
*/

import fs from 'node:fs/promises';
import path from 'node:path';
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in environment.');
  process.exit(1);
}

const inputPath = process.argv[2] || path.resolve(process.cwd(), 'auth_export.json');

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

function asBool(v) {
  if (typeof v === 'boolean') return v;
  if (v === 'true' || v === '1') return true;
  return false;
}

async function main() {
  const raw = await fs.readFile(inputPath, 'utf8');
  const data = JSON.parse(raw);
  const users = Array.isArray(data) ? data : data.users || [];
  console.log(`Loaded ${users.length} Firebase users from ${inputPath}`);

  const results = [];
  for (const u of users) {
    const email = u.email?.trim();
    if (!email) {
      console.warn('Skipping user without email:', u.localId);
      continue;
    }

    // Create user in Supabase Auth
    const { data: created, error: createErr } = await supabase.auth.admin.createUser({
      email,
      email_confirm: asBool(u.emailVerified) || false,
      user_metadata: {
        display_name: u.displayName || '',
        firebase_local_id: u.localId,
      },
      // Note: cannot migrate passwords; users will need to reset
    });

    if (createErr) {
      console.error('Create user failed:', email, createErr.message);
      results.push({ email, status: 'error', error: createErr.message });
      continue;
    }

    // Generate a recovery (password reset) link and print it
    const { data: linkData, error: linkErr } = await supabase.auth.admin.generateLink({
      type: 'recovery',
      email,
    });

    if (linkErr) {
      console.error('Generate recovery link failed:', email, linkErr.message);
      results.push({ email, status: 'created_no_link', user_id: created.user.id });
    } else {
      console.log(`[RESET_LINK] ${email}: ${linkData.properties?.action_link || linkData.action_link}`);
      results.push({ email, status: 'created_with_link', user_id: created.user.id });
    }
  }

  const ok = results.filter(r => r.status.startsWith('created')).length;
  const err = results.filter(r => r.status === 'error').length;
  console.log(`Done. Created: ${ok}, Errors: ${err}`);
}

main().catch((e) => {
  console.error('Fatal error:', e);
  process.exit(1);
});
