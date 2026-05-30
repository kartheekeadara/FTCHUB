-- ============================================================================
-- FTC HUB - Fix Leave Team RLS Policy (URGENT)
-- ============================================================================
-- This fixes the issue where users cannot leave teams due to RLS policy
-- 
-- ISSUE: The profiles_update_team_members policy's WITH CHECK clause was
--        blocking users from setting their team_id to NULL when leaving.
--        The policy checked team_id equality which fails when setting to NULL.
-- ============================================================================

-- ============================================================================
-- Fix: Update profiles_update_team_members policy to allow leaving teams
-- ============================================================================

DROP POLICY IF EXISTS "profiles_update_team_members" ON profiles;

-- CRITICAL FIX: Use SECURITY DEFINER helper functions to avoid infinite recursion
-- This policy should ONLY match when updating OTHER users' profiles, NOT own profile
-- Own profile updates are handled by profiles_update_own policy to avoid recursion
CREATE POLICY "profiles_update_team_members" ON profiles
    FOR UPDATE 
    TO authenticated
    USING (
        -- CRITICAL: Only match when updating OTHER users' profiles (not own profile)
        -- This prevents both policies from matching simultaneously, avoiding recursion
        id != (select auth.uid())
        -- AND user must be a coach of the same team (only check when old team_id is NOT NULL)
        AND profiles.team_id IS NOT NULL 
        AND user_has_team_role((select auth.uid()), profiles.team_id, ARRAY['coach']::TEXT[])
    )
    WITH CHECK (
        -- CRITICAL FIX: Since USING clause ensures id != auth.uid(), we only need to validate
        -- that the user is a coach and the profile being updated has a team_id
        -- This policy will NEVER match when user updates own profile, preventing recursion
        -- User must be a coach
        get_user_team_role_from_auth() = 'coach'
        -- And the profile being updated must have a team_id (not leaving)
        AND profiles.team_id IS NOT NULL
        -- And both must be in the same team
        AND user_has_team_role((select auth.uid()), profiles.team_id, ARRAY['coach']::TEXT[])
    );

