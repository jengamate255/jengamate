-- Firebase to Supabase User Migration
-- Generated on 2025-08-18T09:37:03.618Z
-- Run this in Supabase SQL Editor


-- User: eatorker@gmail.com
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
  'eatorker@gmail.com',
  NULL,
  NOW(),
  NOW(),
  '{"display_name": "", "firebase_local_id": "SHSppdgKd8NXWUZ8KMLxnW0raik1"}',
  '{}'
) ON CONFLICT (email) DO NOTHING;


-- User: pipsr101@gmail.com
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
  'pipsr101@gmail.com',
  NULL,
  NOW(),
  NOW(),
  '{"display_name": "", "firebase_local_id": "u4ATrnNz0oRGX2XOi4MI1HBwDTH2"}',
  '{}'
) ON CONFLICT (email) DO NOTHING;


-- User: dd396515@gmail.com
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
  'dd396515@gmail.com',
  NULL,
  NOW(),
  NOW(),
  '{"display_name": "kkman255", "firebase_local_id": "viE8YSqABAQehyTqtK7pXjIJsag2"}',
  '{}'
) ON CONFLICT (email) DO NOTHING;


-- User: devydee@live.com
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
  'devydee@live.com',
  NULL,
  NOW(),
  NOW(),
  '{"display_name": "", "firebase_local_id": "xBifERVj5AVVElOKk9wuPVpnfPS2"}',
  '{}'
) ON CONFLICT (email) DO NOTHING;


-- User: xiaodongliulxd66369644@gmail.com
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
  'xiaodongliulxd66369644@gmail.com',
  NULL,
  NOW(),
  NOW(),
  '{"display_name": "", "firebase_local_id": "zP5gKg5rDcZEAdVnOlSAXDcEfJ12"}',
  '{}'
) ON CONFLICT (email) DO NOTHING;


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
