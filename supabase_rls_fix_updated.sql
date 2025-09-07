-- Supabase RLS Policy Fix for payment_proofs bucket
-- Updated with secure RLS policies

-- First, drop existing policies if they exist
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow authenticated users to upload payment proofs') THEN
        DROP POLICY "Allow authenticated users to upload payment proofs" ON storage.objects;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow authenticated users to read payment proofs') THEN
        DROP POLICY "Allow authenticated users to read payment proofs" ON storage.objects;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow authenticated users to update payment proofs') THEN
        DROP POLICY "Allow authenticated users to update payment proofs" ON storage.objects;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow authenticated users to delete payment proofs') THEN
        DROP POLICY "Allow authenticated users to delete payment proofs" ON storage.objects;
    END IF;
END $$;

-- Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy 1: Allow authenticated users to upload files to payment_proofs bucket
-- Only allow uploads to a user-specific folder
CREATE POLICY "Allow authenticated users to upload to their folder"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'payment_proofs' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 2: Allow users to read their own files
CREATE POLICY "Allow users to read their own files"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'payment_proofs' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 3: Allow users to update their own files
CREATE POLICY "Allow users to update their own files"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'payment_proofs' AND
    (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
    bucket_id = 'payment_proofs' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 4: Allow users to delete their own files
CREATE POLICY "Allow users to delete their own files"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'payment_proofs' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Grant necessary permissions (minimal required)
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO authenticated;

-- Verify policies are created
SELECT * FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects';