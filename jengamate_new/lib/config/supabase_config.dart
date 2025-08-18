class SupabaseConfig {
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://ednovyqzrbaiyzlegbmy.supabase.co');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVkbm92eXF6cmJhaXl6bGVnYm15Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNTQ4NzQsImV4cCI6MjA3MDczMDg3NH0.G8kfMHO5mRCpgjAQXNV2tdJ8zzTn3zF9la80n3RODu8');
}
