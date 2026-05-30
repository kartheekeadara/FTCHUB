-- ============================================================================
-- FTC HUB - Create RPC function to remove team members (bypasses RLS)
-- ============================================================================

DROP FUNCTION IF EXISTS public.remove_team_member(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.remove_team_member(TEXT, TEXT) CASCADE;

CREATE OR REPLACE FUNCTION public.remove_team_member(
    p_member_id TEXT,
    p_remover_id TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_member_id UUID;
    v_remover_id UUID;
    v_member_team_id UUID;
    v_remover_team_id UUID;
    v_remover_team_role TEXT;
    v_team_coach_id UUID;
BEGIN
    -- Convert strings to UUIDs
    BEGIN
        v_member_id := p_member_id::UUID;
        v_remover_id := p_remover_id::UUID;
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Invalid UUID format';
    END;
    
    -- Verify the remover is authenticated
    IF v_remover_id != auth.uid() THEN
        RAISE EXCEPTION 'Can only remove members as the authenticated user';
    END IF;
    
    -- Get member's current team_id
    SELECT team_id INTO v_member_team_id
    FROM profiles
    WHERE id = v_member_id;
    
    -- If member has no team, nothing to do
    IF v_member_team_id IS NULL THEN
        RETURN;
    END IF;
    
    -- Get remover's team info
    SELECT team_id, team_role INTO v_remover_team_id, v_remover_team_role
    FROM profiles
    WHERE id = v_remover_id;
    
    -- Get team's coach_id
    SELECT coach_id INTO v_team_coach_id
    FROM teams
    WHERE id = v_member_team_id;
    
    -- Verify permission: remover must be:
    -- 1. The member themselves (removing themselves)
    -- 2. A coach/captain of the same team
    -- 3. The team creator (coach_id matches)
    IF v_member_id = v_remover_id THEN
        -- User is removing themselves - allow it
        NULL;
    ELSIF v_remover_team_id = v_member_team_id 
          AND v_remover_team_role IN ('coach', 'captain') THEN
        -- Remover is coach/captain of the same team - allow it
        NULL;
    ELSIF v_team_coach_id = v_remover_id THEN
        -- Remover is the team creator - allow it
        NULL;
    ELSE
        RAISE EXCEPTION 'Insufficient permissions to remove team member';
    END IF;
    
    -- Prevent removing the last coach
    -- CRITICAL FIX: Cast enum to TEXT when comparing with text string
    IF EXISTS (
        SELECT 1 FROM profiles
        WHERE team_id = v_member_team_id
        AND team_role::TEXT = 'coach'
        AND id = v_member_id
    ) THEN
        IF (SELECT COUNT(*) FROM profiles WHERE team_id = v_member_team_id AND team_role::TEXT = 'coach') <= 1 THEN
            RAISE EXCEPTION 'Cannot remove the last coach from the team';
        END IF;
    END IF;
    
    -- Remove member from team (set team_id and team_role to NULL)
    UPDATE profiles
    SET 
        team_id = NULL,
        team_role = NULL,
        updated_at = NOW()
    WHERE id = v_member_id;
    
END;
$$;

GRANT EXECUTE ON FUNCTION public.remove_team_member(TEXT, TEXT) TO authenticated;
ALTER FUNCTION public.remove_team_member(TEXT, TEXT) OWNER TO postgres;





