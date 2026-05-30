-- Pre-submission security hardening (mirror of 13_pre_submission_security_hardening.sql)

CREATE OR REPLACE FUNCTION public.create_user_profile(
    p_email TEXT,
    p_first_name TEXT,
    p_last_name TEXT,
    p_user_id TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    BEGIN
        v_user_id := p_user_id::UUID;
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Invalid user ID format: %', p_user_id;
    END;

    IF auth.uid() IS NULL OR auth.uid() <> v_user_id THEN
        RAISE EXCEPTION 'Not authorized to create profile for this user';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = v_user_id) THEN
        RAISE EXCEPTION 'User does not exist in auth.users';
    END IF;

    INSERT INTO public.profiles (
        id, email, first_name, last_name, role, created_at, updated_at
    )
    VALUES (
        v_user_id,
        COALESCE(NULLIF(p_email, ''), ''),
        COALESCE(NULLIF(p_first_name, ''), ''),
        COALESCE(NULLIF(p_last_name, ''), ''),
        'readonly',
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        updated_at = NOW();
END;
$$;

REVOKE ALL ON FUNCTION public.create_user_profile(TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_user_profile(TEXT, TEXT, TEXT, TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION public.create_user_profile(TEXT, TEXT, TEXT, TEXT) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.get_user_profile(p_user_id TEXT)
RETURNS TABLE (
    id UUID,
    team_id UUID,
    role user_role,
    team_role team_management_role,
    first_name VARCHAR,
    last_name VARCHAR,
    email VARCHAR,
    phone VARCHAR,
    grade INTEGER,
    member_role member_role,
    experience_badges TEXT[],
    emergency_contact_name VARCHAR,
    emergency_contact_phone VARCHAR,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    BEGIN
        v_user_id := p_user_id::UUID;
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Invalid user ID format: %', p_user_id;
    END;

    IF auth.uid() IS NULL OR auth.uid() <> v_user_id THEN
        RAISE EXCEPTION 'Not authorized to read this profile';
    END IF;

    RETURN QUERY
    SELECT
        p.id, p.team_id, p.role, p.team_role, p.first_name, p.last_name, p.email,
        p.phone, p.grade, p.member_role, p.experience_badges,
        p.emergency_contact_name, p.emergency_contact_phone, p.created_at, p.updated_at
    FROM public.profiles p
    WHERE p.id = v_user_id;
END;
$$;

REVOKE ALL ON FUNCTION public.get_user_profile(TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_user_profile(TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_user_profile(TEXT) TO authenticated, service_role;

DROP POLICY IF EXISTS "profiles_insert_own" ON profiles;
CREATE POLICY "profiles_insert_own" ON profiles
    FOR INSERT TO authenticated
    WITH CHECK (id = (SELECT auth.uid()) AND (SELECT auth.uid()) IS NOT NULL AND email IS NOT NULL);

DROP POLICY IF EXISTS "alliance_history_insert_authenticated" ON alliance_history;
DROP POLICY IF EXISTS "alliance_history_update_authenticated" ON alliance_history;
DROP POLICY IF EXISTS "alliance_history_delete_authenticated" ON alliance_history;

DROP POLICY IF EXISTS content_reports_update_team_admin ON content_reports;
CREATE POLICY content_reports_update_team_admin ON content_reports
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles reviewer
            JOIN profiles reporter ON reporter.id = content_reports.reported_by
            WHERE reviewer.id = auth.uid()
              AND reviewer.team_role IN ('coach', 'captain')
              AND reviewer.team_id IS NOT NULL
              AND reviewer.team_id = reporter.team_id
        )
    );

DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
CREATE POLICY "profiles_update_own" ON profiles
    FOR UPDATE TO authenticated
    USING (id = (SELECT auth.uid()))
    WITH CHECK (
        id = (SELECT auth.uid())
        AND (
            team_id IS NOT DISTINCT FROM (SELECT p.team_id FROM profiles p WHERE p.id = auth.uid())
            OR public.can_user_leave_team()
        )
    );
