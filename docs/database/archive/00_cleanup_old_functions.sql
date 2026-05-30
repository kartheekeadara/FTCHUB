-- ============================================================================
-- CLEANUP: Remove Old Function Versions
-- ============================================================================
-- Run this FIRST if you get "function name is not unique" error
-- This removes all old versions of create_user_profile function
-- ============================================================================

-- Drop all versions of create_user_profile function
DROP FUNCTION IF EXISTS public.create_user_profile(UUID, TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.create_user_profile(TEXT, TEXT, TEXT, TEXT) CASCADE;

-- Verify they're gone (should return 0 rows)
SELECT 
    proname as function_name,
    pg_get_function_identity_arguments(oid) as arguments
FROM pg_proc 
WHERE proname = 'create_user_profile' 
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ============================================================================
-- If the above query returns any rows, those functions still exist
-- You may need to drop them manually with their exact signatures
-- ============================================================================

