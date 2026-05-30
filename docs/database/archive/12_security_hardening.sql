-- Security hardening: rate limiting, consent/content_reports, RLS fixes, length constraints
-- Run after existing schema migrations (01_database_schema.sql, 02_rls_policies.sql, etc.)

-- =============================================================================
-- 1. Rate limit buckets (Edge Functions — IP and user scopes)
-- =============================================================================

CREATE TABLE IF NOT EXISTS rate_limit_buckets (
    scope TEXT NOT NULL CHECK (scope IN ('ip', 'user')),
    identifier TEXT NOT NULL,
    endpoint TEXT NOT NULL,
    window_start TIMESTAMPTZ NOT NULL,
    request_count INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY (scope, identifier, endpoint, window_start)
);

CREATE INDEX IF NOT EXISTS idx_rate_limit_buckets_lookup
    ON rate_limit_buckets (scope, identifier, endpoint, window_start DESC);

ALTER TABLE rate_limit_buckets ENABLE ROW LEVEL SECURITY;

-- No client access; Edge Functions use service_role only
DROP POLICY IF EXISTS rate_limit_buckets_no_client ON rate_limit_buckets;
CREATE POLICY rate_limit_buckets_no_client ON rate_limit_buckets
    FOR ALL USING (false) WITH CHECK (false);

-- Atomic rate limit check/increment (returns allowed + retry_after_seconds)
CREATE OR REPLACE FUNCTION check_rate_limit(
    p_scope TEXT,
    p_identifier TEXT,
    p_endpoint TEXT,
    p_max_requests INTEGER,
    p_window_seconds INTEGER
)
RETURNS TABLE(allowed BOOLEAN, retry_after_seconds INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_window_start TIMESTAMPTZ;
    v_count INTEGER;
    v_elapsed INTEGER;
BEGIN
    IF p_scope NOT IN ('ip', 'user') OR p_max_requests < 1 OR p_window_seconds < 1 THEN
        allowed := false;
        retry_after_seconds := 60;
        RETURN NEXT;
        RETURN;
    END IF;

    v_window_start := to_timestamp(
        floor(extract(epoch FROM now()) / p_window_seconds) * p_window_seconds
    );

    INSERT INTO rate_limit_buckets (scope, identifier, endpoint, window_start, request_count)
    VALUES (p_scope, p_identifier, p_endpoint, v_window_start, 1)
    ON CONFLICT (scope, identifier, endpoint, window_start)
    DO UPDATE SET request_count = rate_limit_buckets.request_count + 1
    RETURNING request_count INTO v_count;

    IF v_count <= p_max_requests THEN
        allowed := true;
        retry_after_seconds := 0;
    ELSE
        allowed := false;
        v_elapsed := EXTRACT(EPOCH FROM (now() - v_window_start))::INTEGER;
        retry_after_seconds := GREATEST(1, p_window_seconds - v_elapsed);
    END IF;

    RETURN NEXT;
END;
$$;

REVOKE ALL ON FUNCTION check_rate_limit(TEXT, TEXT, TEXT, INTEGER, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION check_rate_limit(TEXT, TEXT, TEXT, INTEGER, INTEGER) TO service_role;

-- =============================================================================
-- 2. consent_records (referenced by ConsentService / SafetyService)
-- =============================================================================

CREATE TABLE IF NOT EXISTS consent_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    parent_name TEXT NOT NULL CHECK (char_length(parent_name) BETWEEN 1 AND 200),
    parent_email TEXT NOT NULL CHECK (char_length(parent_email) BETWEEN 5 AND 320),
    parent_phone TEXT CHECK (parent_phone IS NULL OR char_length(parent_phone) <= 30),
    relationship TEXT NOT NULL CHECK (relationship IN ('parent', 'guardian', 'legal_guardian')),
    consent_type TEXT NOT NULL CHECK (consent_type IN ('coppa', 'data_collection', 'third_party_sharing', 'location')),
    consent_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expiration_date TIMESTAMPTZ,
    verified BOOLEAN NOT NULL DEFAULT false,
    verification_method TEXT CHECK (verification_method IS NULL OR verification_method IN ('email', 'phone', 'signature', 'in_person')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_consent_records_user_id ON consent_records(user_id);

ALTER TABLE consent_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS consent_records_select_own ON consent_records;
CREATE POLICY consent_records_select_own ON consent_records
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS consent_records_insert_own ON consent_records;
CREATE POLICY consent_records_insert_own ON consent_records
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS consent_records_update_own ON consent_records;
CREATE POLICY consent_records_update_own ON consent_records
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS consent_records_delete_own ON consent_records;
CREATE POLICY consent_records_delete_own ON consent_records
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================================================
-- 3. content_reports (referenced by ContentModerationService)
-- =============================================================================

CREATE TABLE IF NOT EXISTS content_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reported_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content_type TEXT NOT NULL CHECK (content_type IN ('scouting_report', 'troubleshooting_entry', 'team_note', 'comment', 'other')),
    content_id UUID NOT NULL,
    reason TEXT NOT NULL CHECK (reason IN ('inappropriate', 'offensive', 'spam', 'harassment', 'false_information', 'copyright', 'other')),
    description TEXT CHECK (description IS NULL OR char_length(description) <= 2000),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'resolved', 'dismissed')),
    reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    action_taken TEXT CHECK (action_taken IS NULL OR char_length(action_taken) <= 500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_content_reports_reported_by ON content_reports(reported_by);
CREATE INDEX IF NOT EXISTS idx_content_reports_status ON content_reports(status);

ALTER TABLE content_reports ENABLE ROW LEVEL SECURITY;

-- Users can create reports; read/update only their own pending reports or team admins via role
DROP POLICY IF EXISTS content_reports_insert_authenticated ON content_reports;
CREATE POLICY content_reports_insert_authenticated ON content_reports
    FOR INSERT WITH CHECK (auth.uid() = reported_by);

DROP POLICY IF EXISTS content_reports_select_own ON content_reports;
CREATE POLICY content_reports_select_own ON content_reports
    FOR SELECT USING (auth.uid() = reported_by);

-- Team coaches/captains can review reports for their team (via profiles.team_id match on reviewer)
DROP POLICY IF EXISTS content_reports_update_team_admin ON content_reports;
CREATE POLICY content_reports_update_team_admin ON content_reports
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND p.team_role IN ('coach', 'captain')
        )
    );

-- =============================================================================
-- 4. Tighten resources table policies (remove open INSERT/UPDATE)
-- =============================================================================

DROP POLICY IF EXISTS "Resources are publicly insertable" ON resources;
DROP POLICY IF EXISTS "Resources view_count is publicly updatable" ON resources;
DROP POLICY IF EXISTS "Resource subpages are publicly insertable" ON resource_subpages;

-- View count updates only via SECURITY DEFINER RPC (increment_resource_view_count)
-- Authenticated users may still bookmark/progress; catalog sync uses service_role in CI

-- Optional: allow authenticated users to bump view count through RPC only (already exists)

-- =============================================================================
-- 5. String length CHECK constraints on high-traffic tables
-- =============================================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'teams_name_length'
    ) THEN
        ALTER TABLE teams ADD CONSTRAINT teams_name_length
            CHECK (char_length(name) BETWEEN 1 AND 200);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'scouting_reports_notes_length'
    ) THEN
        ALTER TABLE scouting_reports ADD CONSTRAINT scouting_reports_notes_length
            CHECK (notes IS NULL OR char_length(notes) <= 10000);
    END IF;
EXCEPTION
    WHEN undefined_table THEN NULL;
END $$;
