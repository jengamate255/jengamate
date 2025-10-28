-- Fix payment proof storage authentication issues
-- This migration addresses the Firebase Auth vs Supabase Auth mismatch

-- Drop existing conflicting policies
DO $$
BEGIN
    -- Drop all existing policies for payment_proofs bucket
    DROP POLICY IF EXISTS "Allow payment proof uploads" ON storage.objects;
    DROP POLICY IF EXISTS "Allow payment proof reads" ON storage.objects;
    DROP POLICY IF EXISTS "Allow payment proof updates" ON storage.objects;
    DROP POLICY IF EXISTS "Allow payment proof deletes" ON storage.objects;
    DROP POLICY IF EXISTS "Users can upload to own folders" ON storage.objects;
    DROP POLICY IF EXISTS "Users can view own files" ON storage.objects;
    DROP POLICY IF EXISTS "Users can update own files" ON storage.objects;
    DROP POLICY IF EXISTS "Users can delete own files" ON storage.objects;
END $$;

-- Create a more permissive policy that works with Firebase Auth
-- Since we can't directly access Firebase user info in Supabase RLS,
-- we'll make the bucket temporarily more permissive and rely on application-level security

-- Policy 1: Allow any authenticated user to upload payment proofs
-- This is more permissive but necessary since Firebase users aren't in Supabase auth
CREATE POLICY "Allow authenticated payment proof uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'payment_proofs' AND
  -- Ensure the path follows our expected structure: user_id/order_id/filename
  array_length(string_to_array(name, '/'), 1) >= 3
);

-- Policy 2: Allow any authenticated user to read payment proofs
-- In production, you might want to restrict this further
CREATE POLICY "Allow authenticated payment proof reads"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'payment_proofs');

-- Policy 3: Allow any authenticated user to update payment proofs
CREATE POLICY "Allow authenticated payment proof updates"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'payment_proofs')
WITH CHECK (bucket_id = 'payment_proofs');

-- Policy 4: Allow any authenticated user to delete payment proofs
CREATE POLICY "Allow authenticated payment proof deletes"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'payment_proofs');

-- Ensure the payment_proofs bucket exists with correct configuration
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'payment_proofs',
    'payment_proofs',
    true, -- Make bucket public for easier access
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'application/pdf'];

-- Grant necessary permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO authenticated;
GRANT USAGE ON SCHEMA storage TO authenticated;

-- Create a function to validate Firebase users in the application
-- This will be used by the application layer for additional security
CREATE OR REPLACE FUNCTION validate_firebase_user_storage_access(
    firebase_uid TEXT,
    storage_path TEXT
) RETURNS BOOLEAN AS $$
BEGIN
    -- Basic validation: ensure the path starts with the user's Firebase UID
    RETURN storage_path LIKE firebase_uid || '/%';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add a comment explaining the security model
COMMENT ON POLICY "Allow authenticated payment proof uploads" ON storage.objects IS 
'Permissive policy for Firebase Auth users. Application layer enforces user-specific folder structure.';

-- Verify the policies are created
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE schemaname = 'storage' 
    AND tablename = 'objects'
    AND policyname LIKE '%payment%'
ORDER BY policyname;