-- ============================================================================
-- FTC HUB - Fix Security Warnings
-- ============================================================================
-- This file fixes all security warnings from Supabase linter:
-- 1. Enables RLS on tables missing it
-- 2. Creates appropriate RLS policies that maintain functionality
-- 3. Fixes SECURITY DEFINER view issue
-- ============================================================================
-- Run this AFTER 02_rls_policies.sql
-- ============================================================================

-- ============================================================================
-- Step 1: Enable RLS on Missing Tables
-- ============================================================================

ALTER TABLE team_statistics ENABLE ROW LEVEL SECURITY;
ALTER TABLE advancement_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE season_advancement_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE alliance_compatibility_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE alliance_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE score_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prediction_accuracy ENABLE ROW LEVEL SECURITY;
ALTER TABLE scoreboard_parsing_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Step 2: Drop and Recreate team_number_lookup View (Remove SECURITY DEFINER)
-- ============================================================================

-- First, check if the view exists and drop it
DROP VIEW IF EXISTS public.team_number_lookup CASCADE;

-- Recreate the view without SECURITY DEFINER
-- This view is used for public team lookups, so it should use caller's permissions
CREATE OR REPLACE VIEW public.team_number_lookup AS
SELECT 
    t.id AS team_id,
    t.number AS team_number,
    t.name AS team_name,
    t.is_public,
    t.city,
    t.state,
    t.country
FROM teams t
WHERE t.is_public = true;

-- Grant access to authenticated and anonymous users for public lookups
GRANT SELECT ON public.team_number_lookup TO authenticated, anon;

-- ============================================================================
-- Step 3: RLS Policies for team_statistics
-- ============================================================================
-- team_statistics: Public read (for team explorer), team-specific write
-- This table contains public statistics that should be readable by anyone
-- but only writable by the team that owns the statistics

-- Drop existing policies if any
DROP POLICY IF EXISTS "team_statistics_select_public" ON team_statistics;
DROP POLICY IF EXISTS "team_statistics_insert_team" ON team_statistics;
DROP POLICY IF EXISTS "team_statistics_update_team" ON team_statistics;
DROP POLICY IF EXISTS "team_statistics_delete_team" ON team_statistics;

-- Public read access (for team explorer)
CREATE POLICY "team_statistics_select_public" ON team_statistics
    FOR SELECT
    USING (true); -- Anyone can read team statistics (public data)

-- Team members can insert their own team's statistics
CREATE POLICY "team_statistics_insert_team" ON team_statistics
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM teams t
            JOIN profiles p ON p.team_id = t.id
            WHERE p.id = auth.uid()
            AND t.number = team_statistics.team_number
        )
    );

-- Team members can update their own team's statistics
CREATE POLICY "team_statistics_update_team" ON team_statistics
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM teams t
            JOIN profiles p ON p.team_id = t.id
            WHERE p.id = auth.uid()
            AND t.number = team_statistics.team_number
        )
    );

-- Team members can delete their own team's statistics
CREATE POLICY "team_statistics_delete_team" ON team_statistics
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM teams t
            JOIN profiles p ON p.team_id = t.id
            WHERE p.id = auth.uid()
            AND t.number = team_statistics.team_number
        )
    );

-- ============================================================================
-- Step 4: RLS Policies for advancement_points
-- ============================================================================
-- advancement_points: Team-specific (has team_id foreign key)
-- Only team members can read/write their own team's advancement points

DROP POLICY IF EXISTS "advancement_points_select_team" ON advancement_points;
DROP POLICY IF EXISTS "advancement_points_insert_team" ON advancement_points;
DROP POLICY IF EXISTS "advancement_points_update_team" ON advancement_points;
DROP POLICY IF EXISTS "advancement_points_delete_team" ON advancement_points;

CREATE POLICY "advancement_points_select_team" ON advancement_points
    FOR SELECT
    USING (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

CREATE POLICY "advancement_points_insert_team" ON advancement_points
    FOR INSERT
    WITH CHECK (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

CREATE POLICY "advancement_points_update_team" ON advancement_points
    FOR UPDATE
    USING (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

CREATE POLICY "advancement_points_delete_team" ON advancement_points
    FOR DELETE
    USING (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

-- ============================================================================
-- Step 5: RLS Policies for season_advancement_summary
-- ============================================================================
-- season_advancement_summary: Team-specific (has team_id foreign key)
-- Only team members can read/write their own team's season summaries

DROP POLICY IF EXISTS "season_advancement_summary_select_team" ON season_advancement_summary;
DROP POLICY IF EXISTS "season_advancement_summary_insert_team" ON season_advancement_summary;
DROP POLICY IF EXISTS "season_advancement_summary_update_team" ON season_advancement_summary;
DROP POLICY IF EXISTS "season_advancement_summary_delete_team" ON season_advancement_summary;

CREATE POLICY "season_advancement_summary_select_team" ON season_advancement_summary
    FOR SELECT
    USING (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

CREATE POLICY "season_advancement_summary_insert_team" ON season_advancement_summary
    FOR INSERT
    WITH CHECK (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

CREATE POLICY "season_advancement_summary_update_team" ON season_advancement_summary
    FOR UPDATE
    USING (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

CREATE POLICY "season_advancement_summary_delete_team" ON season_advancement_summary
    FOR DELETE
    USING (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

-- ============================================================================
-- Step 6: RLS Policies for alliance_compatibility_scores
-- ============================================================================
-- alliance_compatibility_scores: Team-specific (has team_id foreign key)
-- Only team members can read/write their own team's alliance compatibility scores

DROP POLICY IF EXISTS "alliance_compatibility_scores_select_team" ON alliance_compatibility_scores;
DROP POLICY IF EXISTS "alliance_compatibility_scores_insert_team" ON alliance_compatibility_scores;
DROP POLICY IF EXISTS "alliance_compatibility_scores_update_team" ON alliance_compatibility_scores;
DROP POLICY IF EXISTS "alliance_compatibility_scores_delete_team" ON alliance_compatibility_scores;

CREATE POLICY "alliance_compatibility_scores_select_team" ON alliance_compatibility_scores
    FOR SELECT
    USING (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

CREATE POLICY "alliance_compatibility_scores_insert_team" ON alliance_compatibility_scores
    FOR INSERT
    WITH CHECK (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

CREATE POLICY "alliance_compatibility_scores_update_team" ON alliance_compatibility_scores
    FOR UPDATE
    USING (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

CREATE POLICY "alliance_compatibility_scores_delete_team" ON alliance_compatibility_scores
    FOR DELETE
    USING (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

-- ============================================================================
-- Step 7: RLS Policies for alliance_history
-- ============================================================================
-- alliance_history: Public read (historical match data, no team_id)
-- This table contains public historical match data that should be readable by anyone
-- Only authenticated users can insert/update/delete (for data integrity)

DROP POLICY IF EXISTS "alliance_history_select_public" ON alliance_history;
DROP POLICY IF EXISTS "alliance_history_insert_authenticated" ON alliance_history;
DROP POLICY IF EXISTS "alliance_history_update_authenticated" ON alliance_history;
DROP POLICY IF EXISTS "alliance_history_delete_authenticated" ON alliance_history;

-- Public read access (historical match data is public)
CREATE POLICY "alliance_history_select_public" ON alliance_history
    FOR SELECT
    USING (true); -- Anyone can read historical alliance data

-- Only authenticated users can insert (to prevent spam)
CREATE POLICY "alliance_history_insert_authenticated" ON alliance_history
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Only authenticated users can update
CREATE POLICY "alliance_history_update_authenticated" ON alliance_history
    FOR UPDATE
    USING (auth.role() = 'authenticated');

-- Only authenticated users can delete
CREATE POLICY "alliance_history_delete_authenticated" ON alliance_history
    FOR DELETE
    USING (auth.role() = 'authenticated');

-- ============================================================================
-- Step 8: RLS Policies for score_predictions
-- ============================================================================
-- score_predictions: Team-specific (has team_id foreign key)
-- Only team members can read/write their own team's score predictions

DROP POLICY IF EXISTS "score_predictions_select_team" ON score_predictions;
DROP POLICY IF EXISTS "score_predictions_insert_team" ON score_predictions;
DROP POLICY IF EXISTS "score_predictions_update_team" ON score_predictions;
DROP POLICY IF EXISTS "score_predictions_delete_team" ON score_predictions;

CREATE POLICY "score_predictions_select_team" ON score_predictions
    FOR SELECT
    USING (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

CREATE POLICY "score_predictions_insert_team" ON score_predictions
    FOR INSERT
    WITH CHECK (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

CREATE POLICY "score_predictions_update_team" ON score_predictions
    FOR UPDATE
    USING (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

CREATE POLICY "score_predictions_delete_team" ON score_predictions
    FOR DELETE
    USING (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

-- ============================================================================
-- Step 9: RLS Policies for prediction_accuracy
-- ============================================================================
-- prediction_accuracy: Team-specific (references score_predictions which has team_id)
-- Only team members can read/write their own team's prediction accuracy data

DROP POLICY IF EXISTS "prediction_accuracy_select_team" ON prediction_accuracy;
DROP POLICY IF EXISTS "prediction_accuracy_insert_team" ON prediction_accuracy;
DROP POLICY IF EXISTS "prediction_accuracy_update_team" ON prediction_accuracy;
DROP POLICY IF EXISTS "prediction_accuracy_delete_team" ON prediction_accuracy;

CREATE POLICY "prediction_accuracy_select_team" ON prediction_accuracy
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM score_predictions sp
            JOIN profiles p ON p.team_id = sp.team_id
            WHERE sp.id = prediction_accuracy.prediction_id
            AND p.id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM matches m
            JOIN profiles p ON p.team_id = m.team_id
            WHERE m.id = prediction_accuracy.match_id
            AND p.id = auth.uid()
        )
    );

CREATE POLICY "prediction_accuracy_insert_team" ON prediction_accuracy
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM score_predictions sp
            JOIN profiles p ON p.team_id = sp.team_id
            WHERE sp.id = prediction_accuracy.prediction_id
            AND p.id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM matches m
            JOIN profiles p ON p.team_id = m.team_id
            WHERE m.id = prediction_accuracy.match_id
            AND p.id = auth.uid()
        )
    );

CREATE POLICY "prediction_accuracy_update_team" ON prediction_accuracy
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM score_predictions sp
            JOIN profiles p ON p.team_id = sp.team_id
            WHERE sp.id = prediction_accuracy.prediction_id
            AND p.id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM matches m
            JOIN profiles p ON p.team_id = m.team_id
            WHERE m.id = prediction_accuracy.match_id
            AND p.id = auth.uid()
        )
    );

CREATE POLICY "prediction_accuracy_delete_team" ON prediction_accuracy
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM score_predictions sp
            JOIN profiles p ON p.team_id = sp.team_id
            WHERE sp.id = prediction_accuracy.prediction_id
            AND p.id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM matches m
            JOIN profiles p ON p.team_id = m.team_id
            WHERE m.id = prediction_accuracy.match_id
            AND p.id = auth.uid()
        )
    );

-- ============================================================================
-- Step 10: RLS Policies for scoreboard_parsing_logs
-- ============================================================================
-- scoreboard_parsing_logs: Team-specific (has team_id foreign key)
-- Only team members can read/write their own team's parsing logs

DROP POLICY IF EXISTS "scoreboard_parsing_logs_select_team" ON scoreboard_parsing_logs;
DROP POLICY IF EXISTS "scoreboard_parsing_logs_insert_team" ON scoreboard_parsing_logs;
DROP POLICY IF EXISTS "scoreboard_parsing_logs_update_team" ON scoreboard_parsing_logs;
DROP POLICY IF EXISTS "scoreboard_parsing_logs_delete_team" ON scoreboard_parsing_logs;

CREATE POLICY "scoreboard_parsing_logs_select_team" ON scoreboard_parsing_logs
    FOR SELECT
    USING (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

CREATE POLICY "scoreboard_parsing_logs_insert_team" ON scoreboard_parsing_logs
    FOR INSERT
    WITH CHECK (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

CREATE POLICY "scoreboard_parsing_logs_update_team" ON scoreboard_parsing_logs
    FOR UPDATE
    USING (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

CREATE POLICY "scoreboard_parsing_logs_delete_team" ON scoreboard_parsing_logs
    FOR DELETE
    USING (
        team_id IN (
            SELECT team_id FROM profiles WHERE id = auth.uid() AND team_id IS NOT NULL
        )
    );

-- ============================================================================
-- Security Fixes Complete!
-- ============================================================================
-- All security warnings have been addressed:
-- 1. ✅ RLS enabled on all 8 tables
-- 2. ✅ Appropriate RLS policies created that maintain functionality
-- 3. ✅ team_number_lookup view recreated without SECURITY DEFINER
-- ============================================================================
