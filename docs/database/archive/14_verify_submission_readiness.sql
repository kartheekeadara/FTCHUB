-- Expanded verification script — run after 13_pre_submission_security_hardening.sql
-- Returns rows with status PASS/FAIL for each check

SELECT 'rls_teams' AS check_name,
       CASE WHEN rowsecurity THEN 'PASS' ELSE 'FAIL' END AS status,
       'teams RLS enabled' AS detail
FROM pg_tables WHERE schemaname = 'public' AND tablename = 'teams'

UNION ALL

SELECT 'table_consent_records',
       CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'consent_records') THEN 'PASS' ELSE 'FAIL' END,
       'consent_records exists'

UNION ALL

SELECT 'table_content_reports',
       CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'content_reports') THEN 'PASS' ELSE 'FAIL' END,
       'content_reports exists'

UNION ALL

SELECT 'table_rate_limit_buckets',
       CASE WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'rate_limit_buckets') THEN 'PASS' ELSE 'FAIL' END,
       'rate_limit_buckets exists'

UNION ALL

SELECT 'rpc_create_user_profile',
       CASE WHEN EXISTS (
           SELECT 1 FROM information_schema.routines
           WHERE routine_schema = 'public' AND routine_name = 'create_user_profile'
       ) THEN 'PASS' ELSE 'FAIL' END,
       'create_user_profile exists'

UNION ALL

SELECT 'rpc_remove_team_member',
       CASE WHEN EXISTS (
           SELECT 1 FROM information_schema.routines
           WHERE routine_schema = 'public' AND routine_name = 'remove_team_member'
       ) THEN 'PASS' ELSE 'FAIL' END,
       'remove_team_member exists'

UNION ALL

SELECT 'anon_revoked_create_user_profile',
       CASE WHEN NOT has_function_privilege('anon', 'public.create_user_profile(text,text,text,text)', 'EXECUTE')
            THEN 'PASS' ELSE 'FAIL' END,
       'anon cannot execute create_user_profile'

UNION ALL

SELECT 'anon_revoked_get_user_profile',
       CASE WHEN NOT has_function_privilege('anon', 'public.get_user_profile(text)', 'EXECUTE')
            THEN 'PASS' ELSE 'FAIL' END,
       'anon cannot execute get_user_profile'

UNION ALL

SELECT 'alliance_history_no_client_write',
       CASE WHEN NOT EXISTS (
           SELECT 1 FROM pg_policies
           WHERE schemaname = 'public' AND tablename = 'alliance_history'
             AND cmd IN ('INSERT', 'UPDATE', 'DELETE')
             AND roles::text LIKE '%authenticated%'
       ) THEN 'PASS' ELSE 'FAIL' END,
       'alliance_history client writes removed'

ORDER BY check_name;
