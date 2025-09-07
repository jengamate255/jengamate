-- Supabase RLS Policy Fix for payment_proofs bucket
-- This script will fix the "row-level security policy" error

-- Step 1: Enable RLS on the storage.objects table if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Step 2: Create policies for the payment_proofs bucket

-- Policy 1: Allow authenticated users to upload files
CREATE POLICY "Allow authenticated users to upload payment proofs"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'payment_proofs' AND
  auth.role() = 'authenticated'
);

-- Policy 2: Allow users to read their own uploaded files
CREATE POLICY "Allow users to read their own payment proofs"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'payment_proofs' AND
  auth.uid() = (storage.foldername(name))[1]
);

-- Policy 3: Allow users to update their own files
CREATE POLICY "Allow users to update their own payment proofs"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'payment_proofs' AND
  auth.uid() = (storage.foldername(name))[1]
)
WITH CHECK (
  bucket_id = 'payment_proofs' AND
  auth.uid() = (storage.foldername(name))[1]
);

-- Policy 4: Allow users to delete their own files
CREATE POLICY "Allow users to delete their own payment proofs"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'payment_proofs' AND
  auth.uid() = (storage.foldername(name))[1]
);

-- Step 3: Grant necessary permissions
GRANT ALL ON storage.objects TO authenticated;

-- Step 4: Verify the policies are created
SELECT * FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects';