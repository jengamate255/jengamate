-- Fix RLS policies for payment_proofs bucket
-- This migration fixes the storage permissions issue

-- Drop existing policies for payment_proofs bucket
DO $$
BEGIN
    -- Drop all existing policies for payment_proofs bucket
    DROP POLICY IF EXISTS "Allow authenticated users to upload to their folder" ON storage.objects;
    DROP POLICY IF EXISTS "Allow users to read their own files" ON storage.objects;
    DROP POLICY IF EXISTS "Allow users to update their own files" ON storage.objects;
    DROP POLICY IF EXISTS "Allow users to delete their own files" ON storage.objects;
    DROP POLICY IF EXISTS "Allow authenticated users to upload payment proofs" ON storage.objects;
    DROP POLICY IF EXISTS "Allow authenticated users to read payment proofs" ON storage.objects;
    DROP POLICY IF EXISTS "Allow authenticated users to update payment proofs" ON storage.objects;
    DROP POLICY IF EXISTS "Allow authenticated users to delete payment proofs" ON storage.objects;
END $$;

-- Create more permissive policies for payment_proofs bucket
-- This allows any authenticated user to upload/read payment proofs

-- Policy 1: Allow authenticated users to upload to payment_proofs bucket
CREATE POLICY "Allow payment proof uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'payment_proofs');

-- Policy 2: Allow authenticated users to read payment proofs
CREATE POLICY "Allow payment proof reads"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'payment_proofs');

-- Policy 3: Allow authenticated users to update payment proofs
CREATE POLICY "Allow payment proof updates"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'payment_proofs')
WITH CHECK (bucket_id = 'payment_proofs');

-- Policy 4: Allow authenticated users to delete payment proofs
CREATE POLICY "Allow payment proof deletes"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'payment_proofs');

-- Ensure the payment_proofs bucket exists and is public
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'payment_proofs',
    'payment_proofs',
    true,
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO authenticated;
GRANT USAGE ON SCHEMA storage TO authenticated;

-- Verify the policies are created
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'storage' 
    AND tablename = 'objects'
    AND policyname LIKE '%payment%';

