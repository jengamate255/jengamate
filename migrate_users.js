// Simple user migration script for Firebase to Supabase
// Run with: node migrate_users.js

const fs = require('fs');

// Read the Firebase auth export
const authData = JSON.parse(fs.readFileSync('auth_export.json', 'utf8'));
const users = authData.users || [];

console.log(`Found ${users.length} users to migrate:`);

// Create SQL statements to insert users directly into Supabase
const sqlStatements = [];

users.forEach((user, index) => {
  const email = user.email;
  const displayName = user.displayName || '';
  const emailVerified = user.emailVerified || false;
  const firebaseId = user.localId;
  
  console.log(`${index + 1}. ${email} (${displayName || 'No display name'})`);
  
  // Create SQL to insert user into auth.users table
  // Note: This is a simplified approach - in production you'd use Supabase Admin API
  const userSql = `
-- User: ${email}
INSERT INTO auth.users (
  id, 
  email, 
  email_confirmed_at,
  created_at,
  updated_at,
  raw_user_meta_data,
  raw_app_meta_data
) VALUES (
  gen_random_uuid(),
  '${email}',
  ${emailVerified ? 'NOW()' : 'NULL'},
  NOW(),
  NOW(),
  '{"display_name": "${displayName}", "firebase_local_id": "${firebaseId}"}',
  '{}'
) ON CONFLICT (email) DO NOTHING;
`;
  
  sqlStatements.push(userSql);
});

// Write SQL file
const sqlContent = `-- Firebase to Supabase User Migration
-- Generated on ${new Date().toISOString()}
-- Run this in Supabase SQL Editor

${sqlStatements.join('\n')}

-- Verify migration
SELECT 
  id, 
  email, 
  email_confirmed_at,
  raw_user_meta_data->>'display_name' as display_name,
  raw_user_meta_data->>'firebase_local_id' as firebase_id,
  created_at
FROM auth.users 
ORDER BY created_at DESC;
`;

fs.writeFileSync('user_migration.sql', sqlContent);
console.log('\n✅ Migration SQL generated: user_migration.sql');
console.log('📝 Run this SQL in your Supabase SQL Editor to migrate users');
console.log('⚠️  Note: Users will need to reset their passwords as Firebase password hashes cannot be migrated');
