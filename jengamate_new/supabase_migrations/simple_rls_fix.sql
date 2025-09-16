-- Simple RLS Fix for payment_proofs bucket
-- Apply this in Supabase Dashboard > SQL Editor

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Allow authenticated users to upload payment proofs" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to read payment proofs" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to update payment proofs" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete payment proofs" ON storage.objects;

-- Create new permissive policies for payment_proofs bucket
CREATE POLICY "payment_proofs_upload_policy"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'payment_proofs');

CREATE POLICY "payment_proofs_read_policy"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'payment_proofs');

CREATE POLICY "payment_proofs_update_policy"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'payment_proofs')
WITH CHECK (bucket_id = 'payment_proofs');

CREATE POLICY "payment_proofs_delete_policy"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'payment_proofs');

