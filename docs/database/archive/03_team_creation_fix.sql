-- ============================================================================
-- FTC HUB - Team Creation Fix (URGENT)
-- ============================================================================
-- This file fixes the critical RLS policy issue preventing team creation
-- Run this AFTER 01_database_schema.sql and 02_rls_policies.sql
-- ============================================================================
-- 
-- ISSUE: "The data couldn't be read because it is missing" error
-- ROOT CAUSE: RLS policies were too restrictive - users couldn't see teams
--             they just created because profile.team_id isn't set until after
--             team creation, but the SELECT policy only checked profile.team_id
-- ============================================================================

-- ============================================================================
-- Fix 1: Update Teams SELECT Policy
-- ============================================================================
-- Allow users to see teams where they are the coach_id (team creator)
-- This is critical because when creating a team, coach_id is set immediately
-- but profile.team_id is updated after, so without this, the user can't
-- see the team they just created until the profile update completes

DROP POLICY IF EXISTS "teams_select_own_team" ON teams;
CREATE POLICY "teams_select_own_team" ON teams
    FOR SELECT USING (
        -- Allow users to see teams where they are a member (via profile.team_id)
        -- CRITICAL FIX: Use SECURITY DEFINER function to avoid infinite recursion
        id = get_user_team_id((select auth.uid()))
        OR
        -- CRITICAL: Allow users to see teams they created (via teams.coach_id)
        -- This is needed because when creating a team, coach_id is set immediately
        -- but profile.team_id is updated after, so without this, the user can't
        -- see the team they just created until the profile update completes
        coach_id = (select auth.uid())
    );

-- ============================================================================
-- Fix 2: Update Teams UPDATE Policy
-- ============================================================================
-- Allow team creators (coach_id) to update their teams
-- This ensures team creators can always update, even if profile update fails

DROP POLICY IF EXISTS "teams_update_own_team" ON teams;
CREATE POLICY "teams_update_own_team" ON teams
    FOR UPDATE USING (
        -- Allow coaches/captains to update teams where they are members
        -- CRITICAL FIX: Use SECURITY DEFINER functions to avoid infinite recursion
        (
            id = get_user_team_id((select auth.uid()))
            AND user_has_team_role((select auth.uid()), id, ARRAY['coach', 'captain']::TEXT[])
        )
        OR
        -- CRITICAL: Allow team creators (coach_id) to update their teams
        -- This ensures team creators can always update, even if profile update fails
        coach_id = (select auth.uid())
    );





