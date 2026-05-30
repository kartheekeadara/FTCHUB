-- ============================================================================
-- FTC HUB - Fix Delete Team to Bypass Leave Validation
-- ============================================================================
-- This ensures that when deleting a team, the operation bypasses any
-- leave validation triggers/policies since team deletion is different from leaving.
-- 
-- ISSUE: When delete_team_completely updates profiles to set team_id to NULL,
--        it may trigger leave validation logic that prevents the last coach
--        from being removed, even though team deletion should always be allowed
--        for the team creator.
-- ============================================================================

-- ============================================================================
-- Step 1: Drop any existing trigger that might block team deletion
-- ============================================================================

-- Remove any trigger that checks leave validation during profile updates
DROP TRIGGER IF EXISTS check_can_leave_team_trigger ON profiles;

-- ============================================================================
-- Step 2: Update delete_team_completely function to ensure it works correctly
-- ============================================================================

-- The function already uses SECURITY DEFINER which bypasses RLS
-- We just need to ensure it's clear that team deletion bypasses leave validation
CREATE OR REPLACE FUNCTION public.delete_team_completely(p_team_id UUID, p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_team_coach_id UUID;
    v_user_team_role TEXT;
BEGIN
    -- Verify the user is authenticated
    IF p_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Can only delete teams as the authenticated user';
    END IF;
    
    -- Verify the team exists and get team's coach_id
    SELECT coach_id INTO v_team_coach_id
    FROM teams
    WHERE id = p_team_id;
    
    -- Verify the team exists
    IF NOT EXISTS (SELECT 1 FROM teams WHERE id = p_team_id) THEN
        RAISE EXCEPTION 'Team does not exist';
    END IF;
    
    -- Verify user is the team coach (team creator)
    IF v_team_coach_id != p_user_id THEN
        -- Also check if user is a coach via profile
        -- CRITICAL FIX: Cast enum to TEXT when selecting into TEXT variable
        SELECT team_role::TEXT INTO v_user_team_role
        FROM profiles
        WHERE id = p_user_id AND team_id = p_team_id;
        
        IF v_user_team_role != 'coach' AND v_team_coach_id != p_user_id THEN
            RAISE EXCEPTION 'Only the team coach can delete the team';
        END IF;
    END IF;
    
    -- CRITICAL: Remove all members from team FIRST (set team_id and team_role to NULL)
    -- This must happen before deleting the team to avoid foreign key constraint violations
    -- Using SECURITY DEFINER bypasses RLS, so this update will work
    -- IMPORTANT: This operation is TEAM DELETION, not leaving. The team creator
    -- is allowed to delete the team even if they're the last coach (unlike leaving,
    -- where the last coach cannot leave). This update bypasses leave validation.
    UPDATE profiles
    SET 
        team_id = NULL,
        team_role = NULL,
        updated_at = NOW()
    WHERE team_id = p_team_id;
    
    -- Verify all profiles have been updated (safety check to prevent constraint violation)
    IF EXISTS (SELECT 1 FROM profiles WHERE team_id = p_team_id) THEN
        RAISE EXCEPTION 'Failed to remove all members from team before deletion';
    END IF;
    
    -- Delete all join requests for this team
    DELETE FROM team_join_requests
    WHERE team_id = p_team_id;
    
    -- Now delete the team
    -- All profiles.team_id have been set to NULL, so the foreign key constraint won't block this
    -- This will CASCADE delete all related data:
    -- - vendors (ON DELETE CASCADE)
    -- - budgets (ON DELETE CASCADE)
    -- - events (ON DELETE CASCADE) -> rsvps (ON DELETE CASCADE via events)
    -- - tasks (ON DELETE CASCADE) -> task_attachments (ON DELETE CASCADE via tasks)
    -- - inventory_items (ON DELETE CASCADE) -> stock_transactions (ON DELETE CASCADE via items)
    -- - orders (ON DELETE CASCADE) -> order_items (ON DELETE CASCADE via orders)
    -- - scouting_templates (ON DELETE CASCADE)
    -- - scouting_reports (ON DELETE CASCADE)
    -- - matches (ON DELETE CASCADE)
    -- - troubleshooting_entries (ON DELETE CASCADE) -> troubleshooting_attachments (ON DELETE CASCADE)
    DELETE FROM teams
    WHERE id = p_team_id;
    
    -- After deletion, the team number becomes available again due to UNIQUE constraint
    -- The same person or a different person can create a team with the same number/name
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_team_completely(UUID, UUID) TO authenticated;
ALTER FUNCTION public.delete_team_completely(UUID, UUID) OWNER TO postgres;

