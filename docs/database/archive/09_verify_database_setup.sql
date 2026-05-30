-- ============================================================================
-- FTC HUB - Verify Database Setup
-- ============================================================================
-- Run this to check if teams table exists and has correct structure
-- Also checks RLS status and function existence
-- ============================================================================

-- Check if teams table exists and has correct structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'teams';

-- Check if RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'teams';

-- Check if your functions exist
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('create_user_profile', 'remove_team_member');




















