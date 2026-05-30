-- FTC HUB - Add password_reset_verified field to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS password_reset_verified BOOLEAN DEFAULT false;

-- Set to true for all existing users who have verified their email
UPDATE profiles 
SET password_reset_verified = true 
WHERE id IN (
    SELECT id FROM auth.users WHERE email_confirmed_at IS NOT NULL
)
AND (password_reset_verified IS NULL OR password_reset_verified = false);

COMMENT ON COLUMN profiles.password_reset_verified IS 
'Controls whether user can reset password. Must be true AND email must be verified for password reset to work.';

-- Helper function to sync password_reset_verified with email verification status
-- DISABLED: This function is disabled to prevent redirect URL issues
-- Setting password_reset_verified to NULL allows password reset without problematic redirects
CREATE OR REPLACE FUNCTION sync_password_reset_verified()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- DISABLED: Do not automatically set password_reset_verified to true
    -- This prevents the "application could not be opened" error with redirect URLs
    -- NULL values allow password reset based on email verification only
    -- UPDATE profiles 
    -- SET password_reset_verified = true 
    -- WHERE id IN (
    --     SELECT id FROM auth.users WHERE email_confirmed_at IS NOT NULL
    -- )
    -- AND (password_reset_verified IS NULL OR password_reset_verified = false);
    
    RAISE NOTICE 'sync_password_reset_verified is disabled to prevent redirect URL issues';
END;
$$;

GRANT EXECUTE ON FUNCTION sync_password_reset_verified() TO authenticated, anon;
ALTER FUNCTION sync_password_reset_verified() OWNER TO postgres;

-- DISABLED: Do not run sync automatically to prevent redirect issues
-- SELECT sync_password_reset_verified();

-- CRITICAL FIX: Set password_reset_verified to NULL for ALL verified users
-- This bypasses the problematic redirect URL that causes "application could not be opened" error
-- NULL allows password reset based on email verification only (no redirect needed)
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    -- Set to NULL for all verified users to avoid redirect URL issues
    UPDATE profiles 
    SET password_reset_verified = NULL 
    WHERE id IN (
        SELECT id FROM auth.users 
        WHERE email_confirmed_at IS NOT NULL
    )
    AND password_reset_verified IS NOT NULL; -- Only update if it's not already NULL
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    IF updated_count > 0 THEN
        RAISE NOTICE 'Set password_reset_verified to NULL for % users to fix redirect issues', updated_count;
    END IF;
END $$;

-- Verification function
CREATE OR REPLACE FUNCTION verify_password_reset_setup(user_email TEXT)
RETURNS TABLE(
    user_id UUID,
    email_verified BOOLEAN,
    password_reset_verified BOOLEAN,
    can_reset_password BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as user_id,
        (au.email_confirmed_at IS NOT NULL) as email_verified,
        COALESCE(p.password_reset_verified, false) as password_reset_verified,
        (au.email_confirmed_at IS NOT NULL AND COALESCE(p.password_reset_verified, false) = true) as can_reset_password
    FROM auth.users au
    LEFT JOIN profiles p ON p.id = au.id
    WHERE au.email = LOWER(TRIM(user_email))
    LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION verify_password_reset_setup(TEXT) TO authenticated, anon;
ALTER FUNCTION verify_password_reset_setup(TEXT) OWNER TO postgres;

-- ============================================================================
-- CRITICAL FIX FOR "APPLICATION COULDN'T BE OPENED" ERROR
-- ============================================================================
-- The error occurs because Supabase is trying to redirect to a URL that can't be opened.
-- 
-- SOLUTION: You MUST configure the redirect URL in Supabase Dashboard:
-- 1. Go to: Supabase Dashboard → Authentication → URL Configuration
-- 2. Site URL: https://your-project-ref.supabase.co
-- 3. Redirect URLs: Add BOTH:
--    a) https://your-project-ref.supabase.co/storage/v1/object/public/verification/email-verification-success.html
--    b) ftchub://auth-callback
--
-- IMPORTANT: The password reset email should redirect to the WEB URL first (the HTML page),
-- NOT directly to the deep link. The HTML page will then redirect to ftchub://auth-callback
--
-- ============================================================================

-- FIX: Reset password_reset_verified to NULL to bypass problematic redirect URLs
-- When password_reset_verified is NULL, the app falls back to email verification only
-- This avoids the "open another application" error with Google redirects
-- 
-- This sets password_reset_verified to NULL for ALL users (both verified and unverified)
-- The app code treats NULL as allowing password reset (email verification only)
-- This is the safest approach to avoid redirect URL configuration issues
UPDATE profiles 
SET password_reset_verified = NULL;

-- Helper function to reset password_reset_verified to NULL for troubleshooting
-- This allows password reset to work without the problematic redirect
CREATE OR REPLACE FUNCTION reset_password_reset_verified_to_null(user_email TEXT DEFAULT NULL)
RETURNS TABLE(
    user_id UUID,
    email TEXT,
    password_reset_verified_reset BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    target_user_id UUID;
    reset_count INTEGER;
BEGIN
    IF user_email IS NOT NULL THEN
        -- Reset for specific user
        SELECT au.id INTO target_user_id
        FROM auth.users au
        WHERE au.email = LOWER(TRIM(user_email))
        LIMIT 1;
        
        IF target_user_id IS NOT NULL THEN
            UPDATE profiles 
            SET password_reset_verified = NULL 
            WHERE id = target_user_id;
            
            GET DIAGNOSTICS reset_count = ROW_COUNT;
            
            RETURN QUERY
            SELECT 
                target_user_id,
                user_email::TEXT,
                (reset_count > 0)::BOOLEAN;
        ELSE
            RETURN QUERY
            SELECT 
                NULL::UUID,
                user_email::TEXT,
                false::BOOLEAN;
        END IF;
    ELSE
        -- Reset for all verified users
        UPDATE profiles 
        SET password_reset_verified = NULL 
        WHERE id IN (
            SELECT id FROM auth.users WHERE email_confirmed_at IS NOT NULL
        )
        AND password_reset_verified = true;
        
        GET DIAGNOSTICS reset_count = ROW_COUNT;
        
        RETURN QUERY
        SELECT 
            NULL::UUID,
            'All verified users'::TEXT,
            (reset_count > 0)::BOOLEAN;
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION reset_password_reset_verified_to_null(TEXT) TO authenticated, anon;
ALTER FUNCTION reset_password_reset_verified_to_null(TEXT) OWNER TO postgres;

-- Update the comment to reflect the new behavior
COMMENT ON COLUMN profiles.password_reset_verified IS 
'Controls password reset redirect behavior. NULL = use email verification only (avoids redirect issues). true = use configured redirect (may cause app opening errors). false = block reset.';

-- CRITICAL: Add trigger to prevent password_reset_verified from being set to true
-- This prevents the "application could not be opened" error
-- If someone tries to set it to true, automatically convert to NULL
CREATE OR REPLACE FUNCTION prevent_password_reset_verified_true()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- If trying to set to true, convert to NULL to avoid redirect issues
    IF NEW.password_reset_verified = true THEN
        NEW.password_reset_verified = NULL;
        RAISE NOTICE 'Converted password_reset_verified from true to NULL to prevent redirect URL issues';
    END IF;
    
    RETURN NEW;
END;
$$;

-- Drop trigger if it exists
DROP TRIGGER IF EXISTS trigger_prevent_password_reset_verified_true ON profiles;

-- Create trigger
CREATE TRIGGER trigger_prevent_password_reset_verified_true
    BEFORE INSERT OR UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION prevent_password_reset_verified_true();

-- Final fix: Ensure ALL existing records have NULL (run this after trigger is created)
UPDATE profiles 
SET password_reset_verified = NULL 
WHERE password_reset_verified IS NOT NULL;

-- ============================================================================
-- DIAGNOSTIC FUNCTION: Check password reset configuration for a user
-- ============================================================================
-- Use this to verify the database state:
-- SELECT * FROM diagnose_password_reset('user@example.com');
-- ============================================================================
CREATE OR REPLACE FUNCTION diagnose_password_reset(user_email TEXT)
RETURNS TABLE(
    user_id UUID,
    email TEXT,
    email_verified BOOLEAN,
    password_reset_verified_status TEXT,
    profile_exists BOOLEAN,
    recommendation TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    target_user_id UUID;
    target_email TEXT;
    email_verified_flag BOOLEAN;
    prv_value BOOLEAN;
    profile_exists_flag BOOLEAN;
    rec_text TEXT;
BEGIN
    -- Get user info
    SELECT 
        au.id,
        au.email,
        (au.email_confirmed_at IS NOT NULL)
    INTO 
        target_user_id,
        target_email,
        email_verified_flag
    FROM auth.users au
    WHERE au.email = LOWER(TRIM(user_email))
    LIMIT 1;
    
    IF target_user_id IS NULL THEN
        RETURN QUERY SELECT 
            NULL::UUID,
            user_email::TEXT,
            false::BOOLEAN,
            'USER NOT FOUND'::TEXT,
            false::BOOLEAN,
            'User does not exist in auth.users'::TEXT;
        RETURN;
    END IF;
    
    -- Check profile
    SELECT 
        EXISTS(SELECT 1 FROM profiles WHERE id = target_user_id),
        password_reset_verified
    INTO 
        profile_exists_flag,
        prv_value
    FROM profiles
    WHERE id = target_user_id;
    
    -- Determine status
    IF prv_value IS NULL THEN
        rec_text := '✅ GOOD: password_reset_verified is NULL - password reset should work via email verification only';
    ELSIF prv_value = true THEN
        rec_text := '❌ PROBLEM: password_reset_verified is TRUE - this causes redirect URL issues. Run: SELECT reset_password_reset_verified_to_null(''' || user_email || ''')';
    ELSE
        rec_text := '❌ BLOCKED: password_reset_verified is FALSE - password reset is blocked';
    END IF;
    
    IF NOT email_verified_flag THEN
        rec_text := rec_text || ' | ⚠️ WARNING: Email is not verified - user must verify email first';
    END IF;
    
    RETURN QUERY SELECT 
        target_user_id,
        target_email,
        email_verified_flag,
        CASE 
            WHEN prv_value IS NULL THEN 'NULL (Good)'
            WHEN prv_value = true THEN 'TRUE (Problem - causes redirect error)'
            ELSE 'FALSE (Blocked)'
        END::TEXT,
        profile_exists_flag,
        rec_text;
END;
$$;

GRANT EXECUTE ON FUNCTION diagnose_password_reset(TEXT) TO authenticated, anon;
ALTER FUNCTION diagnose_password_reset(TEXT) OWNER TO postgres;

-- ============================================================================
-- QUICK FIX FUNCTION: Fix password reset for a specific user
-- ============================================================================
-- Usage: SELECT * FROM fix_password_reset_for_user('user@example.com');
-- ============================================================================
CREATE OR REPLACE FUNCTION fix_password_reset_for_user(user_email TEXT)
RETURNS TABLE(
    user_id UUID,
    email TEXT,
    fixed BOOLEAN,
    message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    target_user_id UUID;
    fix_count INTEGER;
BEGIN
    -- Get user ID
    SELECT au.id INTO target_user_id
    FROM auth.users au
    WHERE au.email = LOWER(TRIM(user_email))
    LIMIT 1;
    
    IF target_user_id IS NULL THEN
        RETURN QUERY SELECT 
            NULL::UUID,
            user_email::TEXT,
            false::BOOLEAN,
            'User not found'::TEXT;
        RETURN;
    END IF;
    
    -- Set password_reset_verified to NULL
    UPDATE profiles 
    SET password_reset_verified = NULL 
    WHERE id = target_user_id;
    
    GET DIAGNOSTICS fix_count = ROW_COUNT;
    
    IF fix_count > 0 THEN
        RETURN QUERY SELECT 
            target_user_id,
            user_email::TEXT,
            true::BOOLEAN,
            'Fixed: Set password_reset_verified to NULL. Make sure Supabase Dashboard redirect URL is configured correctly.'::TEXT;
    ELSE
        RETURN QUERY SELECT 
            target_user_id,
            user_email::TEXT,
            false::BOOLEAN,
            'No changes needed or profile does not exist'::TEXT;
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION fix_password_reset_for_user(TEXT) TO authenticated, anon;
ALTER FUNCTION fix_password_reset_for_user(TEXT) OWNER TO postgres;
