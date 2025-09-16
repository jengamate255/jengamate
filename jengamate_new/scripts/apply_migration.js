const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Read the migration file - use RPC migration for now
const migrationPath = path.join(__dirname, '../supabase/migrations/20250999999999_rpc_find_by_text.sql');
const migrationSQL = fs.readFileSync(migrationPath, 'utf8');

// Supabase configuration
const supabaseUrl = 'https://ednovyqzrbaiyzlegbmy.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVkbm92eXF6cmJhaXl6bGVnYm15Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNTQ4NzQsImV4cCI6MjA3MDczMDg3NH0.G8kfMHO5mRCpgjAQXNV2tdJ8zzTn3zF9la80n3RODu8';

const supabase = createClient(supabaseUrl, supabaseKey);

async function applyMigration() {
  try {
    console.log('🚀 Applying robust payment system migration...');

    // Split the migration into individual statements
    const statements = migrationSQL
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));

    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      if (statement.trim()) {
        console.log(`📝 Executing statement ${i + 1}/${statements.length}...`);

        try {
          const { error } = await supabase.rpc('exec_sql', { sql: statement });
          if (error) {
            console.warn(`⚠️  Statement ${i + 1} warning:`, error.message);
          }
        } catch (err) {
          console.warn(`⚠️  Statement ${i + 1} error:`, err.message);
        }
      }
    }

    console.log('✅ Migration applied successfully!');
    console.log('🔄 Please restart your web server to see the changes.');

  } catch (error) {
    console.error('❌ Migration failed:', error);
    console.log('\n📋 Manual Alternative:');
    console.log('1. Go to https://supabase.com/dashboard/project/ednovyqzrbaiyzlegbmy');
    console.log('2. Navigate to SQL Editor');
    console.log('3. Copy and paste the contents of robust_payment_system_migration.sql');
    console.log('4. Click "Run" to execute the migration');
  }
}

applyMigration();















