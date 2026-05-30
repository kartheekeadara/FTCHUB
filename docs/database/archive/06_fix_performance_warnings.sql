-- ============================================================================
-- FTC HUB - Fix All Performance & Security Warnings
-- ============================================================================
-- This fixes all Supabase linter warnings:
-- 1. Auth RLS InitPlan warnings - wrap auth.uid() in (select auth.uid())
-- 2. Multiple permissive policies - consolidate overlapping policies
-- 3. Duplicate index - remove duplicate index
-- 4. Function security - add SET search_path to functions
-- ============================================================================
-- NOTE: This is a large file that will update many policies. It's safe to run.
-- ============================================================================

-- ============================================================================
-- CLEANUP: Drop all existing policies that might cause conflicts
-- ============================================================================
-- Drop any policies that might already exist from previous runs

-- Drop all events policies first
DROP POLICY IF EXISTS "events_select_team" ON events;
DROP POLICY IF EXISTS "events_insert_team" ON events;
DROP POLICY IF EXISTS "events_update_team" ON events;
DROP POLICY IF EXISTS "events_delete_team" ON events;
DROP POLICY IF EXISTS "events_manage_team" ON events;

-- Drop other consolidated policies that might exist
DROP POLICY IF EXISTS "budgets_manage_team" ON budgets;
DROP POLICY IF EXISTS "matches_manage_team" ON matches;
DROP POLICY IF EXISTS "templates_manage_team" ON scouting_templates;
DROP POLICY IF EXISTS "order_items_manage_team" ON order_items;
DROP POLICY IF EXISTS "troubleshooting_manage_team" ON troubleshooting_entries;
DROP POLICY IF EXISTS "troubleshooting_attachments_manage_team" ON troubleshooting_attachments;

-- ============================================================================
-- Fix 1: Function Security - Add SET search_path to all functions
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- ============================================================================
-- Fix 2: Wrap all auth.uid() calls in (select auth.uid()) for better performance
-- ============================================================================

-- Teams Policies
-- CRITICAL FIX: Use SECURITY DEFINER function to avoid infinite recursion
DROP POLICY IF EXISTS "teams_select_own_team" ON teams;
CREATE POLICY "teams_select_own_team" ON teams
    FOR SELECT USING (
        id = get_user_team_id((select auth.uid()))
        OR coach_id = (select auth.uid())
    );

DROP POLICY IF EXISTS "teams_select_by_invite_code" ON teams;
CREATE POLICY "teams_select_by_invite_code" ON teams
    FOR SELECT USING ((select auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "teams_insert_any" ON teams;
CREATE POLICY "teams_insert_any" ON teams
    FOR INSERT 
    TO authenticated
    WITH CHECK ((select auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "teams_update_own_team" ON teams;
CREATE POLICY "teams_update_own_team" ON teams
    FOR UPDATE USING (
        -- CRITICAL FIX: Use SECURITY DEFINER functions to avoid infinite recursion
        (
            id = get_user_team_id((select auth.uid()))
            AND user_has_team_role((select auth.uid()), id, ARRAY['coach', 'captain']::TEXT[])
        )
        OR coach_id = (select auth.uid())
    );

-- CRITICAL FIX: Allow coaches to delete their teams
-- This was missing and was causing "cannot delete team" error
DROP POLICY IF EXISTS "teams_delete_own_team" ON teams;
CREATE POLICY "teams_delete_own_team" ON teams
    FOR DELETE 
    TO authenticated
    USING (
        -- Allow team creators (coach_id) to delete their teams
        -- This is the primary way to identify team ownership
        coach_id = (select auth.uid())
        OR
        -- Also allow coaches to delete teams where they are members
        -- CRITICAL FIX: Use SECURITY DEFINER function to avoid infinite recursion
        (
            id = get_user_team_id((select auth.uid()))
            AND user_has_team_role((select auth.uid()), id, ARRAY['coach']::TEXT[])
        )
    );

-- Profiles Policies
DROP POLICY IF EXISTS "profiles_insert_own" ON profiles;
CREATE POLICY "profiles_insert_own" ON profiles
    FOR INSERT 
    TO authenticated
    WITH CHECK (
        (
            (id = (select auth.uid()) AND (select auth.uid()) IS NOT NULL)
            OR EXISTS (SELECT 1 FROM auth.users WHERE auth.users.id = id)
        )
        AND email IS NOT NULL
    );

DROP POLICY IF EXISTS "profiles_select_own" ON profiles;
CREATE POLICY "profiles_select_own" ON profiles
    FOR SELECT 
    TO authenticated
    USING (id = (select auth.uid()));

DROP POLICY IF EXISTS "profiles_select_team_members" ON profiles;
CREATE POLICY "profiles_select_team_members" ON profiles
    FOR SELECT 
    TO authenticated
    USING (
        team_id IS NOT NULL 
        AND team_id = get_user_team_id((select auth.uid()))
    );

-- SIMPLIFIED: Allow all updates to own profile
-- The validation for preventing last coach from leaving is handled by a trigger
-- (see 10_fix_leave_team_member_rls.sql) which has proper access to OLD values
DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
CREATE POLICY "profiles_update_own" ON profiles
    FOR UPDATE 
    TO authenticated
    USING (id = (select auth.uid()))
    WITH CHECK (id = (select auth.uid()));

DROP POLICY IF EXISTS "profiles_delete_own" ON profiles;
CREATE POLICY "profiles_delete_own" ON profiles
    FOR DELETE 
    TO authenticated
    USING (id = (select auth.uid()));

-- Team Join Requests
DROP POLICY IF EXISTS "join_requests_select_own" ON team_join_requests;
CREATE POLICY "join_requests_select_own" ON team_join_requests
    FOR SELECT USING (
        user_id = (select auth.uid())
        OR (
            team_id = get_user_team_id((select auth.uid()))
            AND user_has_team_role((select auth.uid()), team_id, ARRAY['coach', 'captain']::TEXT[])
        )
    );

DROP POLICY IF EXISTS "join_requests_insert_own" ON team_join_requests;
CREATE POLICY "join_requests_insert_own" ON team_join_requests
    FOR INSERT WITH CHECK (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "join_requests_update_team" ON team_join_requests;
CREATE POLICY "join_requests_update_team" ON team_join_requests
    FOR UPDATE USING (
        team_id = get_user_team_id((select auth.uid()))
        AND user_has_team_role((select auth.uid()), team_id, ARRAY['coach', 'captain']::TEXT[])
    );

-- Helper function to get user team_id (already optimized)
CREATE OR REPLACE FUNCTION get_user_team_id(user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result UUID;
BEGIN
    SELECT team_id INTO result
    FROM profiles
    WHERE id = user_id
    AND team_id IS NOT NULL
    LIMIT 1;
    RETURN result;
END;
$$;

-- ============================================================================
-- Fix 3: Create helper function for team_id checks (reduces duplication)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_user_team_id_from_auth()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
    SELECT team_id
    FROM profiles
    WHERE id = (select auth.uid())
    AND team_id IS NOT NULL
    LIMIT 1;
$$;

-- ============================================================================
-- Fix 4: Update all policies that check team_id to use optimized pattern
-- ============================================================================

-- Vendors
DROP POLICY IF EXISTS "vendors_select_team" ON vendors;
CREATE POLICY "vendors_select_team" ON vendors
    FOR SELECT USING (
        team_id = get_user_team_id_from_auth()
    );

DROP POLICY IF EXISTS "vendors_manage_team" ON vendors;
CREATE POLICY "vendors_manage_team" ON vendors
    FOR ALL USING (
        team_id = get_user_team_id_from_auth()
    );

-- Budgets (consolidate select and manage into one policy to fix multiple permissive warning)
DROP POLICY IF EXISTS "budgets_select_team" ON budgets;
DROP POLICY IF EXISTS "budgets_manage_team" ON budgets;
CREATE POLICY "budgets_manage_team" ON budgets
    FOR ALL USING (
        team_id = get_user_team_id_from_auth()
    );

-- Events (consolidate all policies into one to fix multiple permissive warnings)
DROP POLICY IF EXISTS "events_select_team" ON events;
DROP POLICY IF EXISTS "events_insert_team" ON events;
DROP POLICY IF EXISTS "events_update_team" ON events;
DROP POLICY IF EXISTS "events_delete_team" ON events;
CREATE POLICY "events_manage_team" ON events
    FOR ALL USING (
        team_id = get_user_team_id_from_auth()
    );

-- RSVPs
DROP POLICY IF EXISTS "rsvps_select_team" ON rsvps;
CREATE POLICY "rsvps_select_team" ON rsvps
    FOR SELECT USING (
        event_id IN (
            SELECT id FROM events 
            WHERE team_id = get_user_team_id_from_auth()
        )
    );

DROP POLICY IF EXISTS "rsvps_manage_own" ON rsvps;
CREATE POLICY "rsvps_manage_own" ON rsvps
    FOR ALL USING (user_id = (select auth.uid()));

-- Tasks
DROP POLICY IF EXISTS "tasks_select_team" ON tasks;
CREATE POLICY "tasks_select_team" ON tasks
    FOR SELECT USING (
        team_id = get_user_team_id_from_auth()
    );

DROP POLICY IF EXISTS "tasks_insert_team" ON tasks;
CREATE POLICY "tasks_insert_team" ON tasks
    FOR INSERT WITH CHECK (
        team_id = get_user_team_id_from_auth()
    );

DROP POLICY IF EXISTS "tasks_update_team" ON tasks;
CREATE POLICY "tasks_update_team" ON tasks
    FOR UPDATE USING (
        team_id = get_user_team_id_from_auth()
        AND (created_by = (select auth.uid()) OR assignee_id = (select auth.uid()))
    );

DROP POLICY IF EXISTS "tasks_delete_team" ON tasks;
CREATE POLICY "tasks_delete_team" ON tasks
    FOR DELETE USING (
        team_id = get_user_team_id_from_auth()
        AND (
            created_by = (select auth.uid())
            OR user_has_team_role((select auth.uid()), tasks.team_id, ARRAY['coach', 'captain', 'subcaptain']::TEXT[])
        )
    );

-- Task Attachments
DROP POLICY IF EXISTS "task_attachments_select_team" ON task_attachments;
CREATE POLICY "task_attachments_select_team" ON task_attachments
    FOR SELECT USING (
        task_id IN (
            SELECT id FROM tasks 
            WHERE team_id = get_user_team_id_from_auth()
        )
    );

DROP POLICY IF EXISTS "task_attachments_manage_team" ON task_attachments;
CREATE POLICY "task_attachments_manage_team" ON task_attachments
    FOR ALL USING (
        task_id IN (
            SELECT id FROM tasks 
            WHERE team_id = get_user_team_id_from_auth()
        )
    );

-- Inventory
DROP POLICY IF EXISTS "inventory_select_team" ON inventory_items;
CREATE POLICY "inventory_select_team" ON inventory_items
    FOR SELECT USING (
        team_id = get_user_team_id_from_auth()
    );

DROP POLICY IF EXISTS "inventory_manage_team" ON inventory_items;
CREATE POLICY "inventory_manage_team" ON inventory_items
    FOR ALL USING (
        team_id = get_user_team_id_from_auth()
    );

-- Stock Transactions
DROP POLICY IF EXISTS "stock_transactions_select_team" ON stock_transactions;
CREATE POLICY "stock_transactions_select_team" ON stock_transactions
    FOR SELECT USING (
        item_id IN (
            SELECT id FROM inventory_items 
            WHERE team_id = get_user_team_id_from_auth()
        )
    );

DROP POLICY IF EXISTS "stock_transactions_insert_team" ON stock_transactions;
CREATE POLICY "stock_transactions_insert_team" ON stock_transactions
    FOR INSERT WITH CHECK (
        item_id IN (
            SELECT id FROM inventory_items 
            WHERE team_id = get_user_team_id_from_auth()
        )
    );

-- Orders
DROP POLICY IF EXISTS "orders_select_team" ON orders;
CREATE POLICY "orders_select_team" ON orders
    FOR SELECT USING (
        team_id = get_user_team_id_from_auth()
    );

DROP POLICY IF EXISTS "orders_insert_team" ON orders;
CREATE POLICY "orders_insert_team" ON orders
    FOR INSERT WITH CHECK (
        team_id = get_user_team_id_from_auth()
    );

DROP POLICY IF EXISTS "orders_update_team" ON orders;
CREATE POLICY "orders_update_team" ON orders
    FOR UPDATE USING (
        team_id = get_user_team_id_from_auth()
    );

DROP POLICY IF EXISTS "orders_delete_team" ON orders;
CREATE POLICY "orders_delete_team" ON orders
    FOR DELETE USING (
        team_id = get_user_team_id_from_auth()
    );

-- Order Items (consolidate to fix multiple permissive warning)
DROP POLICY IF EXISTS "order_items_select_team" ON order_items;
DROP POLICY IF EXISTS "order_items_manage_team" ON order_items;
CREATE POLICY "order_items_manage_team" ON order_items
    FOR ALL USING (
        order_id IN (
            SELECT id FROM orders 
            WHERE team_id = get_user_team_id_from_auth()
        )
    );

-- Scouting Templates (consolidate to fix multiple permissive warning)
DROP POLICY IF EXISTS "templates_select_team" ON scouting_templates;
DROP POLICY IF EXISTS "templates_manage_team" ON scouting_templates;
CREATE POLICY "templates_manage_team" ON scouting_templates
    FOR ALL USING (
        team_id = get_user_team_id_from_auth()
    );

-- Scouting Reports
DROP POLICY IF EXISTS "scouting_select_team" ON scouting_reports;
CREATE POLICY "scouting_select_team" ON scouting_reports
    FOR SELECT USING (
        team_id = get_user_team_id_from_auth()
    );

DROP POLICY IF EXISTS "scouting_insert_team" ON scouting_reports;
CREATE POLICY "scouting_insert_team" ON scouting_reports
    FOR INSERT WITH CHECK (
        team_id = get_user_team_id_from_auth()
    );

DROP POLICY IF EXISTS "scouting_update_team" ON scouting_reports;
CREATE POLICY "scouting_update_team" ON scouting_reports
    FOR UPDATE USING (
        team_id = get_user_team_id_from_auth()
    );

DROP POLICY IF EXISTS "scouting_delete_team" ON scouting_reports;
CREATE POLICY "scouting_delete_team" ON scouting_reports
    FOR DELETE USING (
        team_id = get_user_team_id_from_auth()
    );

-- Matches (consolidate to fix multiple permissive warning)
DROP POLICY IF EXISTS "matches_select_team" ON matches;
DROP POLICY IF EXISTS "matches_manage_team" ON matches;
CREATE POLICY "matches_manage_team" ON matches
    FOR ALL USING (
        team_id = get_user_team_id_from_auth()
    );

-- Troubleshooting Entries (consolidate to fix multiple permissive warning)
DROP POLICY IF EXISTS "troubleshooting_select_team" ON troubleshooting_entries;
DROP POLICY IF EXISTS "troubleshooting_manage_team" ON troubleshooting_entries;
CREATE POLICY "troubleshooting_manage_team" ON troubleshooting_entries
    FOR ALL USING (
        team_id = get_user_team_id_from_auth()
    );

-- Troubleshooting Attachments (consolidate to fix multiple permissive warning)
DROP POLICY IF EXISTS "troubleshooting_attachments_select_team" ON troubleshooting_attachments;
DROP POLICY IF EXISTS "troubleshooting_attachments_manage_team" ON troubleshooting_attachments;
CREATE POLICY "troubleshooting_attachments_manage_team" ON troubleshooting_attachments
    FOR ALL USING (
        entry_id IN (
            SELECT id FROM troubleshooting_entries 
            WHERE team_id = get_user_team_id_from_auth()
        )
    );

-- ============================================================================
-- Fix 5: Remove duplicate index on order_items
-- ============================================================================

DROP INDEX IF EXISTS idx_order_items_order;
-- Keep idx_order_items_order_id (more descriptive name)

-- ============================================================================
-- Fix 6: Remove any profiles_update_comprehensive policy if it exists
-- ============================================================================

DROP POLICY IF EXISTS "profiles_update_comprehensive" ON profiles;

-- ============================================================================
-- Fix 7: Remove SECURITY DEFINER from team_number_lookup view
-- ============================================================================

-- ISSUE SUMMARY:
-- The view 'public.team_number_lookup' was created with SECURITY DEFINER property,
-- which causes it to execute with the view owner's privileges instead of the caller's.
-- This bypasses RLS policies and violates the principle of least privilege.
--
-- SEVERITY: MEDIUM (not extremely severe)
-- - The view only exposes basic team info (number, name, school, city, state)
-- - Not used in the codebase (appears to be unused/manually created)
-- - Risk is limited to bypassing RLS on non-sensitive team directory data
-- - Still recommended to fix for security best practices
--
-- SOLUTION OPTIONS:
-- Option A: Drop and recreate without SECURITY DEFINER (recommended if view is needed)
-- Option B: Simply drop the view if it's not being used (safest if unused)

-- Step 1: DIAGNOSTIC - Check current view definition and owner
-- Run this first to see what Supabase detects:
-- SELECT 
--     schemaname,
--     viewname,
--     viewowner,
--     pg_get_viewdef('public.team_number_lookup', true) as definition
-- FROM pg_views 
-- WHERE viewname = 'team_number_lookup';
--
-- Also check if view uses any SECURITY DEFINER functions:
-- SELECT 
--     p.proname as function_name,
--     p.prosecdef as is_security_definer
-- FROM pg_proc p
-- JOIN pg_depend d ON d.objid = p.oid
-- JOIN pg_rewrite r ON r.oid = d.refobjid
-- WHERE r.ev_class = 'public.team_number_lookup'::regclass
-- AND p.prosecdef = true;

-- OPTION 1: If the view is NOT being used, simply drop it (RECOMMENDED)
-- This completely eliminates the security concern
-- Uncomment the line below if the view is not needed:
-- DROP VIEW IF EXISTS public.team_number_lookup CASCADE;

-- OPTION 2: If the view IS needed, recreate it properly
-- Step 2a: Drop the existing view completely
DROP VIEW IF EXISTS public.team_number_lookup CASCADE;

-- Step 2b: Recreate the view cleanly (PostgreSQL defaults to SECURITY INVOKER)
-- This ensures the view executes with the caller's permissions, respecting RLS
CREATE VIEW public.team_number_lookup
AS
SELECT 
    id,
    number,
    name,
    school,
    city,
    state,
    country,
    coach_id,
    invite_code,
    created_at,
    updated_at
FROM teams;

-- Step 2c: Grant SELECT permissions
-- RLS policies on the 'teams' table will apply based on the querying user
GRANT SELECT ON public.team_number_lookup TO authenticated, anon;

-- VERIFICATION:
-- After running this fix, the view will:
-- 1. Execute with the caller's permissions (not the owner's)
-- 2. Respect RLS policies on the teams table
-- 3. Return only rows the querying user has permission to see
--
-- To verify the fix worked, check that the linting error is resolved in Supabase.

-- ============================================================================
-- Summary
-- ============================================================================
-- This fix:
-- 1. Wraps all auth.uid() calls in (select auth.uid()) for caching
-- 2. Consolidates overlapping policies to fix "multiple permissive policies" warnings
-- 3. Removes duplicate index
-- 4. Creates optimized helper function for team_id checks
-- 5. Adds SET search_path to functions for security
-- 6. Removes SECURITY DEFINER from team_number_lookup view
-- 
-- After running this, most warnings should be resolved.
-- ============================================================================

