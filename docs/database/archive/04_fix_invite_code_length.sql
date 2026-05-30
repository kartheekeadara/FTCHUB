-- ============================================================================
-- FTC HUB - Fix Invite Code Length Error (URGENT)
-- ============================================================================
-- This fixes: "value too long for type character varying(6)" error
-- 
-- ISSUE: The app generates 8-10 character invite codes, but the database
--        column is VARCHAR(6), causing insert failures.
-- ============================================================================

-- ============================================================================
-- Fix: Change invite_code column from VARCHAR(6) to VARCHAR(10)
-- ============================================================================

DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'teams' 
        AND column_name = 'invite_code'
        AND character_maximum_length = 6
    ) THEN
        RAISE NOTICE 'Found invite_code column with length 6, changing to 10...';
        
        -- Drop the unique constraint temporarily (required to alter column)
        IF EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'teams_invite_code_unique' 
            AND table_name = 'teams'
        ) THEN
            ALTER TABLE teams DROP CONSTRAINT teams_invite_code_unique;
            RAISE NOTICE 'Dropped unique constraint temporarily';
        END IF;
        
        -- Alter the column to VARCHAR(10)
        ALTER TABLE teams ALTER COLUMN invite_code TYPE VARCHAR(10);
        RAISE NOTICE 'Changed invite_code column from VARCHAR(6) to VARCHAR(10)';
        
        -- Recreate the unique constraint
        ALTER TABLE teams ADD CONSTRAINT teams_invite_code_unique UNIQUE (invite_code);
        RAISE NOTICE 'Recreated unique constraint';
        
        RAISE NOTICE '✅ Fix complete! invite_code column is now VARCHAR(10)';
    ELSIF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'teams' 
        AND column_name = 'invite_code'
        AND character_maximum_length = 10
    ) THEN
        RAISE NOTICE '✅ invite_code column is already VARCHAR(10) - no fix needed';
    END IF;
END $$;




















