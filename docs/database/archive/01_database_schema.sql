-- ============================================================================
-- FTC HUB - Complete Database Schema
-- ============================================================================
-- This is the MAIN database setup file. Run this FIRST.
-- Creates all tables, enums, triggers, indexes, and migrations.
-- ============================================================================

-- ===========================================================================
-- Extensions
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- Enum Types
-- ============================================================================

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('admin', 'editor', 'readonly');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'member_role') THEN
        CREATE TYPE member_role AS ENUM ('driver', 'programmer', 'builder', 'scout', 'coach', 'mentor');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'team_management_role') THEN
        CREATE TYPE team_management_role AS ENUM ('coach', 'captain', 'subcaptain', 'member');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'event_status') THEN
        CREATE TYPE event_status AS ENUM ('scheduled', 'in_progress', 'completed', 'cancelled');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_status') THEN
        CREATE TYPE task_status AS ENUM ('todo', 'doing', 'done');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'match_phase') THEN
        CREATE TYPE match_phase AS ENUM ('auto', 'teleop', 'endgame');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
        CREATE TYPE order_status AS ENUM ('pending', 'ordered', 'received', 'cancelled');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'alliance_color') THEN
        CREATE TYPE alliance_color AS ENUM ('red', 'blue');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'match_status') THEN
        CREATE TYPE match_status AS ENUM ('scheduled', 'in_progress', 'completed', 'forfeited');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'transaction_type') THEN
        CREATE TYPE transaction_type AS ENUM ('in', 'out', 'adjustment');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'rsvp_status') THEN
        CREATE TYPE rsvp_status AS ENUM ('pending', 'attending', 'declined');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'join_request_status') THEN
        CREATE TYPE join_request_status AS ENUM ('pending', 'approved', 'rejected');
    END IF;
END $$;

-- ============================================================================
-- Tables
-- ============================================================================

-- Teams
CREATE TABLE IF NOT EXISTS teams (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        VARCHAR(255) NOT NULL,
    number      VARCHAR(10)  NOT NULL UNIQUE,
    school      VARCHAR(255),
    city        VARCHAR(100),
    state       VARCHAR(50),
    country     VARCHAR(50) NOT NULL DEFAULT 'USA',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Profiles (extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
    id                       UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    team_id                  UUID REFERENCES teams(id) ON DELETE SET NULL,
    role                     user_role    NOT NULL DEFAULT 'readonly',
    first_name               VARCHAR(100),
    last_name                VARCHAR(100),
    email                    VARCHAR(255) NOT NULL UNIQUE,
    phone                    VARCHAR(20),
    grade                    INTEGER,
    member_role              member_role,
    experience_badges        TEXT[],
    emergency_contact_name   VARCHAR(100),
    emergency_contact_phone  VARCHAR(20),
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_team_id ON profiles(team_id);

-- Team Join Requests
CREATE TABLE IF NOT EXISTS team_join_requests (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id        UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    invite_code    VARCHAR(10) NOT NULL,
    status         join_request_status NOT NULL DEFAULT 'pending',
    message        TEXT,
    responded_by   UUID REFERENCES profiles(id) ON DELETE SET NULL,
    responded_at   TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_team_join_requests_team_id ON team_join_requests(team_id);
CREATE INDEX IF NOT EXISTS idx_team_join_requests_user_id ON team_join_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_team_join_requests_status ON team_join_requests(status);
CREATE INDEX IF NOT EXISTS idx_team_join_requests_team_status ON team_join_requests(team_id, status);
CREATE UNIQUE INDEX IF NOT EXISTS idx_team_join_requests_unique_pending 
    ON team_join_requests(team_id, user_id) 
    WHERE status = 'pending';

-- Vendors
CREATE TABLE IF NOT EXISTS vendors (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id             UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    name                VARCHAR(255) NOT NULL,
    contact_person      VARCHAR(255),
    email               VARCHAR(255),
    phone               VARCHAR(50),
    website             VARCHAR(255),
    address             VARCHAR(255),
    notes               TEXT,
    rating              INTEGER CHECK (rating IS NULL OR (rating >= 1 AND rating <= 5)),
    average_delivery_days NUMERIC(5,2),
    total_orders        INTEGER DEFAULT 0,
    total_spent         NUMERIC(12,2) DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vendors_team_id ON vendors(team_id);

-- Budgets
CREATE TABLE IF NOT EXISTS budgets (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id      UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    name         VARCHAR(255) NOT NULL,
    description  TEXT,
    total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0),
    start_date   TIMESTAMPTZ   NOT NULL,
    end_date     TIMESTAMPTZ   NOT NULL,
    categories   JSONB         NOT NULL DEFAULT '[]'::jsonb,
    created_by   UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_budgets_team_id ON budgets(team_id);

-- Events
CREATE TABLE IF NOT EXISTS events (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id             UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    title               VARCHAR(255) NOT NULL,
    description         TEXT,
    start_date          TIMESTAMPTZ NOT NULL,
    end_date            TIMESTAMPTZ,
    location            VARCHAR(255),
    event_type          VARCHAR(50),
    status              event_status NOT NULL DEFAULT 'scheduled',
    google_calendar_id  VARCHAR(255),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_events_team_id    ON events(team_id);
CREATE INDEX IF NOT EXISTS idx_events_start_date ON events(start_date);

-- RSVPs
CREATE TABLE IF NOT EXISTS rsvps (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id   UUID NOT NULL REFERENCES events(id)   ON DELETE CASCADE,
    user_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status     rsvp_status NOT NULL DEFAULT 'pending',
    notes      TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (event_id, user_id)
);

-- Tasks
CREATE TABLE IF NOT EXISTS tasks (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id     UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    title       VARCHAR(255) NOT NULL,
    description TEXT,
    status      task_status NOT NULL DEFAULT 'todo',
    priority    INTEGER     NOT NULL DEFAULT 1 CHECK (priority BETWEEN 1 AND 4),
    assignee_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    assignee_ids UUID[] DEFAULT ARRAY[]::UUID[],
    due_date    TIMESTAMPTZ,
    created_by  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tasks_team_id ON tasks(team_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status  ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date) WHERE due_date IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_assignee_id ON tasks(assignee_id) WHERE assignee_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_team_due_date ON tasks(team_id, due_date) WHERE due_date IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_created_by ON tasks(created_by);

-- Task Attachments
CREATE TABLE IF NOT EXISTS task_attachments (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id    UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    file_name  VARCHAR(255) NOT NULL,
    file_path  TEXT NOT NULL,
    file_size  INTEGER CHECK (file_size IS NULL OR file_size >= 0),
    mime_type  VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Inventory Items
CREATE TABLE IF NOT EXISTS inventory_items (
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id            UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    sku                VARCHAR(100) NOT NULL,
    name               VARCHAR(255) NOT NULL,
    manufacturer       VARCHAR(100),
    part_number        VARCHAR(100),
    category           VARCHAR(100),
    location           VARCHAR(100),
    quantity_on_hand   INTEGER NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
    low_stock_threshold INTEGER NOT NULL DEFAULT 5 CHECK (low_stock_threshold >= 0),
    unit_cost          NUMERIC(10,2) CHECK (unit_cost IS NULL OR unit_cost >= 0),
    description        TEXT,
    image_url          TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (team_id, sku)
);

CREATE INDEX IF NOT EXISTS idx_inventory_team_id ON inventory_items(team_id);

-- Stock Transactions
CREATE TABLE IF NOT EXISTS stock_transactions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    item_id         UUID NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
    user_id         UUID REFERENCES profiles(id) ON DELETE SET NULL,
    transaction_type transaction_type NOT NULL,
    quantity        INTEGER NOT NULL CHECK (quantity <> 0),
    reason          VARCHAR(255),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stock_transactions_item ON stock_transactions(item_id);

-- Orders
CREATE TABLE IF NOT EXISTS orders (
    id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id               UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    order_number          VARCHAR(100) UNIQUE,
    vendor                VARCHAR(255),
    total_amount          NUMERIC(10,2) CHECK (total_amount IS NULL OR total_amount >= 0),
    order_date            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status                order_status NOT NULL DEFAULT 'pending',
    notes                 TEXT,
    receipt_url           TEXT,
    receipt_urls          JSONB DEFAULT '[]'::jsonb,
    budget_id             UUID REFERENCES budgets(id) ON DELETE SET NULL,
    budget_category_id    UUID,
    expected_delivery_date TIMESTAMPTZ,
    actual_delivery_date  TIMESTAMPTZ,
    created_by            UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_team_status ON orders(team_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_team_date   ON orders(team_id, order_date DESC);

-- Order Items
CREATE TABLE IF NOT EXISTS order_items (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id    UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    item_id     UUID REFERENCES inventory_items(id) ON DELETE SET NULL,
    description VARCHAR(255) NOT NULL,
    quantity    INTEGER       NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    total_price NUMERIC(10,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_item_id ON order_items(item_id) WHERE item_id IS NOT NULL;

-- Scouting Templates
CREATE TABLE IF NOT EXISTS scouting_templates (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id       UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    name          VARCHAR(255) NOT NULL,
    description   TEXT,
    is_default    BOOLEAN NOT NULL DEFAULT FALSE,
    template_data JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(template_data) = 'object'),
    created_by    UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_templates_team          ON scouting_templates(team_id);
CREATE INDEX IF NOT EXISTS idx_templates_team_default  ON scouting_templates(team_id, is_default);

-- Scouting Reports
CREATE TABLE IF NOT EXISTS scouting_reports (
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id            UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    template_id        UUID REFERENCES scouting_templates(id) ON DELETE SET NULL,
    scouted_team_number VARCHAR(10) NOT NULL,
    match_number       VARCHAR(20),
    event_name         VARCHAR(255),
    phase              match_phase,
    scout_id           UUID REFERENCES profiles(id) ON DELETE SET NULL,
    report_data        JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(report_data) = 'object'),
    notes              TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_scouting_team_id      ON scouting_reports(team_id);
CREATE INDEX IF NOT EXISTS idx_scouting_scouted_team ON scouting_reports(scouted_team_number);
CREATE INDEX IF NOT EXISTS idx_scouting_template_id  ON scouting_reports(template_id);

-- Phase 5: Add Pit Scouting Fields to scouting_reports
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'scouting_reports' AND column_name = 'is_pit_scouting') THEN
        ALTER TABLE scouting_reports ADD COLUMN is_pit_scouting BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'scouting_reports' AND column_name = 'pit_scouting_data') THEN
        ALTER TABLE scouting_reports ADD COLUMN pit_scouting_data JSONB;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'scouting_reports' AND column_name = 'robot_images') THEN
        ALTER TABLE scouting_reports ADD COLUMN robot_images JSONB DEFAULT '[]'::jsonb;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'scouting_reports' AND column_name = 'robot_videos') THEN
        ALTER TABLE scouting_reports ADD COLUMN robot_videos JSONB DEFAULT '[]'::jsonb;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'scouting_reports' AND column_name = 'profile_version') THEN
        ALTER TABLE scouting_reports ADD COLUMN profile_version INTEGER DEFAULT 1;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'scouting_reports' AND column_name = 'is_current_profile') THEN
        ALTER TABLE scouting_reports ADD COLUMN is_current_profile BOOLEAN DEFAULT TRUE;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_scouting_pit_scouting ON scouting_reports(is_pit_scouting) WHERE is_pit_scouting = TRUE;
CREATE INDEX IF NOT EXISTS idx_scouting_current_profile ON scouting_reports(scouted_team_number, is_current_profile) WHERE is_pit_scouting = TRUE AND is_current_profile = TRUE;

-- Matches
CREATE TABLE IF NOT EXISTS matches (
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id            UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    match_number       VARCHAR(20) NOT NULL,
    scheduled_time     TIMESTAMPTZ NOT NULL,
    alliance_color     alliance_color NOT NULL,
    alliance_partner_1 INTEGER,
    alliance_partner_2 INTEGER,
    opponent_1         INTEGER,
    opponent_2         INTEGER,
    opponent_3         INTEGER,
    status             match_status NOT NULL DEFAULT 'scheduled',
    our_score          INTEGER,
    opponent_score     INTEGER,
    location           VARCHAR(255),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_matches_team_time ON matches(team_id, scheduled_time);
CREATE INDEX IF NOT EXISTS idx_matches_status    ON matches(status);

-- Team Statistics (Phase 1: OPR, DPR, CCWM)
CREATE TABLE IF NOT EXISTS team_statistics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_number VARCHAR(10) NOT NULL,
    event_name VARCHAR(255),
    season_year INTEGER,
    
    -- Core Statistics
    opr NUMERIC(8,2),
    dpr NUMERIC(8,2),
    ccwm NUMERIC(8,2),
    
    -- Match Counts
    matches_played INTEGER DEFAULT 0,
    wins INTEGER DEFAULT 0,
    losses INTEGER DEFAULT 0,
    ties INTEGER DEFAULT 0,
    
    -- Scoring Statistics
    average_score NUMERIC(8,2),
    average_alliance_score NUMERIC(8,2),
    average_opponent_score NUMERIC(8,2),
    highest_score INTEGER,
    lowest_score INTEGER,
    
    -- Phase Statistics
    average_auto_score NUMERIC(8,2),
    average_teleop_score NUMERIC(8,2),
    average_endgame_score NUMERIC(8,2),
    
    -- Reliability Metrics
    win_rate NUMERIC(5,4),
    consistency_score NUMERIC(5,4),
    
    -- Rankings
    opr_rank INTEGER,
    ccwm_rank INTEGER,
    win_rate_rank INTEGER,
    
    -- Metadata
    last_calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    calculation_method VARCHAR(50) DEFAULT 'linear_algebra',
    matches_used INTEGER,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(team_number, event_name, season_year)
);

CREATE INDEX IF NOT EXISTS idx_team_statistics_team_number ON team_statistics(team_number);
CREATE INDEX IF NOT EXISTS idx_team_statistics_event ON team_statistics(event_name, season_year);
CREATE INDEX IF NOT EXISTS idx_team_statistics_opr ON team_statistics(opr DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_team_statistics_ccwm ON team_statistics(ccwm DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_team_statistics_season ON team_statistics(season_year);

-- Advancement Points (Phase 2: Advancement Tracking)
CREATE TABLE IF NOT EXISTS advancement_points (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    team_number VARCHAR(10) NOT NULL,
    
    -- Event Information
    event_name VARCHAR(255) NOT NULL,
    event_type VARCHAR(50), -- 'qualifier', 'championship', 'state'
    event_date DATE,
    season_year INTEGER NOT NULL,
    
    -- Qualification Points
    win_points INTEGER DEFAULT 0,
    tie_points INTEGER DEFAULT 0,
    ranking_points INTEGER DEFAULT 0,
    award_points INTEGER DEFAULT 0,
    total_qualification_points INTEGER DEFAULT 0,
    
    -- Playoff Points
    alliance_selection_points INTEGER DEFAULT 0,
    playoff_match_points INTEGER DEFAULT 0,
    championship_points INTEGER DEFAULT 0,
    total_playoff_points INTEGER DEFAULT 0,
    
    -- Rankings
    final_ranking INTEGER,
    total_teams INTEGER,
    
    -- Awards
    awards_won JSONB DEFAULT '[]'::jsonb,
    
    -- Advancement Status
    advanced_to_next_level BOOLEAN DEFAULT FALSE,
    next_level_event VARCHAR(255),
    
    -- Metadata
    verified BOOLEAN DEFAULT FALSE,
    source VARCHAR(50) DEFAULT 'manual',
    notes TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(team_id, event_name, season_year)
);

CREATE INDEX IF NOT EXISTS idx_advancement_team ON advancement_points(team_id);
CREATE INDEX IF NOT EXISTS idx_advancement_team_number ON advancement_points(team_number);
CREATE INDEX IF NOT EXISTS idx_advancement_season ON advancement_points(season_year);
CREATE INDEX IF NOT EXISTS idx_advancement_event ON advancement_points(event_name);

-- Season Advancement Summary (Phase 2: Advancement Tracking)
CREATE TABLE IF NOT EXISTS season_advancement_summary (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    team_number VARCHAR(10) NOT NULL,
    season_year INTEGER NOT NULL,
    
    -- Cumulative Points
    total_qualification_points INTEGER DEFAULT 0,
    total_playoff_points INTEGER DEFAULT 0,
    total_points INTEGER DEFAULT 0,
    
    -- Event Counts
    events_attended INTEGER DEFAULT 0,
    events_won INTEGER DEFAULT 0,
    events_advanced INTEGER DEFAULT 0,
    
    -- Current Status
    current_level VARCHAR(50),
    advancement_status VARCHAR(50),
    next_milestone VARCHAR(255),
    points_to_next_milestone INTEGER,
    
    -- Rankings
    season_ranking INTEGER,
    total_teams_in_season INTEGER,
    
    last_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(team_id, season_year)
);

CREATE INDEX IF NOT EXISTS idx_season_summary_team ON season_advancement_summary(team_id);
CREATE INDEX IF NOT EXISTS idx_season_summary_season ON season_advancement_summary(season_year);
CREATE INDEX IF NOT EXISTS idx_season_summary_points ON season_advancement_summary(total_points DESC);

-- Alliance Compatibility Scores (Phase 3: Alliance Intelligence)
CREATE TABLE IF NOT EXISTS alliance_compatibility_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    event_name VARCHAR(255),
    
    -- Alliance Composition
    captain_team_number VARCHAR(10) NOT NULL,
    partner1_team_number VARCHAR(10),
    partner2_team_number VARCHAR(10),
    
    -- Compatibility Scores
    overall_compatibility NUMERIC(5,4) NOT NULL,
    phase_coverage_score NUMERIC(5,4),
    complementary_strengths_score NUMERIC(5,4),
    historical_synergy_score NUMERIC(5,4),
    strategic_compatibility_score NUMERIC(5,4),
    reliability_score NUMERIC(5,4),
    
    -- Phase Analysis
    auto_coverage NUMERIC(5,4),
    teleop_coverage NUMERIC(5,4),
    endgame_coverage NUMERIC(5,4),
    
    -- Recommendations
    recommendation_level VARCHAR(20),
    key_strengths TEXT[],
    potential_weaknesses TEXT[],
    strategic_notes TEXT,
    
    -- Metadata
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    calculation_version VARCHAR(20) DEFAULT '1.0',
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(team_id, captain_team_number, partner1_team_number, partner2_team_number, event_name)
);

CREATE INDEX IF NOT EXISTS idx_compatibility_team ON alliance_compatibility_scores(team_id);
CREATE INDEX IF NOT EXISTS idx_compatibility_captain ON alliance_compatibility_scores(captain_team_number);
CREATE INDEX IF NOT EXISTS idx_compatibility_score ON alliance_compatibility_scores(overall_compatibility DESC);

-- Alliance History (Phase 3: Alliance Intelligence)
CREATE TABLE IF NOT EXISTS alliance_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_name VARCHAR(255) NOT NULL,
    match_number VARCHAR(20) NOT NULL,
    
    -- Red Alliance
    red_team1 VARCHAR(10) NOT NULL,
    red_team2 VARCHAR(10) NOT NULL,
    red_team3 VARCHAR(10) NOT NULL,
    red_score INTEGER,
    
    -- Blue Alliance
    blue_team1 VARCHAR(10) NOT NULL,
    blue_team2 VARCHAR(10) NOT NULL,
    blue_team3 VARCHAR(10) NOT NULL,
    blue_score INTEGER,
    
    -- Results
    winner VARCHAR(10), -- 'red' or 'blue'
    match_date TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(event_name, match_number)
);

-- Index for searching by team numbers (using B-tree composite index)
CREATE INDEX IF NOT EXISTS idx_alliance_history_teams ON alliance_history(red_team1, red_team2, red_team3, blue_team1, blue_team2, blue_team3);
CREATE INDEX IF NOT EXISTS idx_alliance_history_event ON alliance_history(event_name);

-- DEPRECATED (Phase 1): Score Predictions - Feature removed as unreliable/unpredictable
-- This table is kept for backward compatibility but is no longer used
-- Score Predictions (Phase 3: Alliance Intelligence)
CREATE TABLE IF NOT EXISTS score_predictions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    event_name VARCHAR(255),
    
    -- Alliance Composition
    captain_team_number VARCHAR(10) NOT NULL,
    partner1_team_number VARCHAR(10),
    partner2_team_number VARCHAR(10),
    
    -- Opponent Alliance (optional)
    opponent1_team_number VARCHAR(10),
    opponent2_team_number VARCHAR(10),
    opponent3_team_number VARCHAR(10),
    
    -- Predictions
    predicted_alliance_score NUMERIC(8,2) NOT NULL,
    predicted_opponent_score NUMERIC(8,2),
    predicted_win_probability NUMERIC(5,4),
    
    -- Confidence Intervals
    score_lower_bound NUMERIC(8,2),
    score_upper_bound NUMERIC(8,2),
    confidence_level NUMERIC(5,4),
    
    -- Breakdown
    predicted_auto_score NUMERIC(8,2),
    predicted_teleop_score NUMERIC(8,2),
    predicted_endgame_score NUMERIC(8,2),
    
    -- Model Information
    prediction_model VARCHAR(50) DEFAULT 'statistical',
    model_version VARCHAR(20) DEFAULT '1.0',
    features_used JSONB,
    
    -- Metadata
    predicted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_predictions_team ON score_predictions(team_id);
CREATE INDEX IF NOT EXISTS idx_predictions_alliance ON score_predictions(captain_team_number, partner1_team_number, partner2_team_number);
CREATE INDEX IF NOT EXISTS idx_predictions_event ON score_predictions(event_name);

-- Prediction Accuracy Tracking (Phase 3: Alliance Intelligence)
CREATE TABLE IF NOT EXISTS prediction_accuracy (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prediction_id UUID REFERENCES score_predictions(id) ON DELETE CASCADE,
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    
    -- Actual Results
    actual_alliance_score INTEGER,
    actual_opponent_score INTEGER,
    actual_winner VARCHAR(10),
    
    -- Accuracy Metrics
    score_error NUMERIC(8,2), -- predicted - actual
    absolute_error NUMERIC(8,2),
    percent_error NUMERIC(5,4),
    prediction_correct BOOLEAN, -- win/loss prediction
    
    -- Analysis
    analyzed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_prediction_accuracy_prediction ON prediction_accuracy(prediction_id);
CREATE INDEX IF NOT EXISTS idx_prediction_accuracy_match ON prediction_accuracy(match_id);

-- DEPRECATED (Phase 1): Scoreboard Parsing Logs - OCR feature removed (redundant with native camera app)
-- This table is kept for backward compatibility but is no longer used
-- Scoreboard Parsing Logs (Phase 4: OCR Analytics - Optional)
CREATE TABLE IF NOT EXISTS scoreboard_parsing_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    
    -- OCR Results
    ocr_confidence NUMERIC(3,2),
    extraction_success BOOLEAN,
    manual_correction_required BOOLEAN,
    
    -- Extracted Data
    extracted_match_number VARCHAR(20),
    extracted_teams JSONB,
    extracted_scores JSONB,
    extracted_penalties JSONB,
    
    -- Processing Info
    processing_time_ms INTEGER,
    image_quality_score NUMERIC(3,2),
    ocr_engine VARCHAR(50) DEFAULT 'vision_framework',
    
    -- User Corrections
    user_corrected BOOLEAN DEFAULT FALSE,
    corrections_made JSONB,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_parsing_logs_match ON scoreboard_parsing_logs(match_id);
CREATE INDEX IF NOT EXISTS idx_parsing_logs_team ON scoreboard_parsing_logs(team_id);

-- Troubleshooting Entries
CREATE TABLE IF NOT EXISTS troubleshooting_entries (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id     UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    title       VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    subsystem   VARCHAR(100),
    solution    TEXT,
    tags        TEXT[],
    created_by  UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_troubleshooting_team ON troubleshooting_entries(team_id);

-- Troubleshooting Attachments
CREATE TABLE IF NOT EXISTS troubleshooting_attachments (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entry_id   UUID NOT NULL REFERENCES troubleshooting_entries(id) ON DELETE CASCADE,
    file_name  VARCHAR(255) NOT NULL,
    file_path  TEXT NOT NULL,
    file_type  VARCHAR(20),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- Functions & Triggers
-- ============================================================================

-- Updated-at trigger function
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

-- Drop existing triggers (safe to re-run)
DROP TRIGGER IF EXISTS trg_update_teams            ON teams;
DROP TRIGGER IF EXISTS trg_update_profiles        ON profiles;
DROP TRIGGER IF EXISTS trg_update_vendors          ON vendors;
DROP TRIGGER IF EXISTS trg_update_budgets          ON budgets;
DROP TRIGGER IF EXISTS trg_update_events           ON events;
DROP TRIGGER IF EXISTS trg_update_rsvps             ON rsvps;
DROP TRIGGER IF EXISTS trg_update_tasks             ON tasks;
DROP TRIGGER IF EXISTS trg_update_inventory         ON inventory_items;
DROP TRIGGER IF EXISTS trg_update_orders            ON orders;
DROP TRIGGER IF EXISTS trg_update_templates         ON scouting_templates;
DROP TRIGGER IF EXISTS trg_update_reports           ON scouting_reports;
DROP TRIGGER IF EXISTS trg_update_matches           ON matches;
DROP TRIGGER IF EXISTS trg_update_troubleshoot      ON troubleshooting_entries;
DROP TRIGGER IF EXISTS trg_update_join_requests     ON team_join_requests;
DROP TRIGGER IF EXISTS trg_update_team_statistics   ON team_statistics;
DROP TRIGGER IF EXISTS trg_update_advancement_points ON advancement_points;
DROP TRIGGER IF EXISTS trg_update_season_summary    ON season_advancement_summary;
DROP TRIGGER IF EXISTS trg_update_alliance_compatibility ON alliance_compatibility_scores;
DROP TRIGGER IF EXISTS trg_update_score_predictions ON score_predictions;

-- Create triggers
CREATE TRIGGER trg_update_teams            BEFORE UPDATE ON teams                   FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_update_profiles          BEFORE UPDATE ON profiles                FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_update_vendors           BEFORE UPDATE ON vendors                 FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_update_budgets           BEFORE UPDATE ON budgets                 FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_update_events            BEFORE UPDATE ON events                  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_update_rsvps             BEFORE UPDATE ON rsvps                   FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_update_tasks             BEFORE UPDATE ON tasks                  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_update_inventory         BEFORE UPDATE ON inventory_items        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_update_orders            BEFORE UPDATE ON orders                 FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_update_templates          BEFORE UPDATE ON scouting_templates     FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_update_reports            BEFORE UPDATE ON scouting_reports       FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_update_matches            BEFORE UPDATE ON matches                FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_update_troubleshoot       BEFORE UPDATE ON troubleshooting_entries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_update_join_requests      BEFORE UPDATE ON team_join_requests     FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_update_team_statistics    BEFORE UPDATE ON team_statistics        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_update_advancement_points BEFORE UPDATE ON advancement_points     FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_update_season_summary     BEFORE UPDATE ON season_advancement_summary FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_update_alliance_compatibility BEFORE UPDATE ON alliance_compatibility_scores FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_update_score_predictions BEFORE UPDATE ON score_predictions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Migrations (Safe to run multiple times)
-- ============================================================================

-- Remove birth_date column if it exists (Phase 1 fix)
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'birth_date'
    ) THEN
        ALTER TABLE profiles DROP COLUMN birth_date;
    END IF;
END $$;

-- Add coach_id and invite_code to teams
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'teams' AND column_name = 'coach_id') THEN
        ALTER TABLE teams ADD COLUMN coach_id UUID;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'teams' AND column_name = 'coach_id') THEN
        CREATE INDEX IF NOT EXISTS idx_teams_coach_id ON teams(coach_id);
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'teams_coach_id_fkey' AND table_name = 'teams'
        ) THEN
            ALTER TABLE teams 
            ADD CONSTRAINT teams_coach_id_fkey 
            FOREIGN KEY (coach_id) REFERENCES profiles(id) ON DELETE SET NULL;
        END IF;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'teams' AND column_name = 'invite_code') THEN
        ALTER TABLE teams ADD COLUMN invite_code VARCHAR(10);
        UPDATE teams SET invite_code = UPPER(
            SUBSTRING(MD5(RANDOM()::TEXT || id::TEXT || NOW()::TEXT) FROM 1 FOR 6)
        ) WHERE invite_code IS NULL;
        ALTER TABLE teams ALTER COLUMN invite_code SET NOT NULL;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'teams_invite_code_unique' AND table_name = 'teams'
        ) THEN
            ALTER TABLE teams ADD CONSTRAINT teams_invite_code_unique UNIQUE (invite_code);
        END IF;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'teams' AND column_name = 'invite_code') THEN
        CREATE INDEX IF NOT EXISTS idx_teams_invite_code ON teams(invite_code);
    END IF;
    
    -- Phase 2: Add public visibility and team profile columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'teams' AND column_name = 'is_public') THEN
        ALTER TABLE teams ADD COLUMN is_public BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'teams' AND column_name = 'website_url') THEN
        ALTER TABLE teams ADD COLUMN website_url VARCHAR(500);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'teams' AND column_name = 'bio') THEN
        ALTER TABLE teams ADD COLUMN bio TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'teams' AND column_name = 'robot_name') THEN
        ALTER TABLE teams ADD COLUMN robot_name VARCHAR(255);
    END IF;
END $$;

-- Add team_role to profiles
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'team_role') THEN
        ALTER TABLE profiles ADD COLUMN team_role team_management_role;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'profiles' AND column_name = 'team_role') THEN
        CREATE INDEX IF NOT EXISTS idx_profiles_team_role ON profiles(team_role);
    END IF;
END $$;

-- Add assignee_ids to tasks (for multiple assignees)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tasks' AND column_name = 'assignee_ids') THEN
        ALTER TABLE tasks ADD COLUMN assignee_ids UUID[] DEFAULT ARRAY[]::UUID[];
    END IF;
END $$;

-- Phase 1: Add statistics calculation fields to matches table
DO $$ 
BEGIN
    -- Red and Blue alliance scores
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'matches' AND column_name = 'red_alliance_score') THEN
        ALTER TABLE matches ADD COLUMN red_alliance_score INTEGER;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'matches' AND column_name = 'blue_alliance_score') THEN
        ALTER TABLE matches ADD COLUMN blue_alliance_score INTEGER;
    END IF;
    
    -- Event information
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'matches' AND column_name = 'event_name') THEN
        ALTER TABLE matches ADD COLUMN event_name VARCHAR(255);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'matches' AND column_name = 'season_year') THEN
        ALTER TABLE matches ADD COLUMN season_year INTEGER;
    END IF;
    
    -- Individual team numbers for alliances (for statistics calculation)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'matches' AND column_name = 'red_team1') THEN
        ALTER TABLE matches ADD COLUMN red_team1 VARCHAR(10);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'matches' AND column_name = 'red_team2') THEN
        ALTER TABLE matches ADD COLUMN red_team2 VARCHAR(10);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'matches' AND column_name = 'red_team3') THEN
        ALTER TABLE matches ADD COLUMN red_team3 VARCHAR(10);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'matches' AND column_name = 'blue_team1') THEN
        ALTER TABLE matches ADD COLUMN blue_team1 VARCHAR(10);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'matches' AND column_name = 'blue_team2') THEN
        ALTER TABLE matches ADD COLUMN blue_team2 VARCHAR(10);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'matches' AND column_name = 'blue_team3') THEN
        ALTER TABLE matches ADD COLUMN blue_team3 VARCHAR(10);
    END IF;
    
    -- Phase 4: OCR Support Fields
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'matches' AND column_name = 'score_source') THEN
        -- DEPRECATED (Phase 1): OCR-related columns - Scoreboard OCR feature removed
        ALTER TABLE matches ADD COLUMN score_source VARCHAR(20) DEFAULT 'manual';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'matches' AND column_name = 'ocr_confidence') THEN
        -- DEPRECATED: OCR feature removed
        ALTER TABLE matches ADD COLUMN ocr_confidence NUMERIC(3,2);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'matches' AND column_name = 'ocr_raw_data') THEN
        -- DEPRECATED: OCR feature removed
        ALTER TABLE matches ADD COLUMN ocr_raw_data JSONB;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'matches' AND column_name = 'penalties_red') THEN
        ALTER TABLE matches ADD COLUMN penalties_red INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'matches' AND column_name = 'penalties_blue') THEN
        ALTER TABLE matches ADD COLUMN penalties_blue INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'matches' AND column_name = 'scoreboard_image_url') THEN
        -- DEPRECATED: OCR feature removed
        ALTER TABLE matches ADD COLUMN scoreboard_image_url TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'matches' AND column_name = 'ocr_processing_time_ms') THEN
        -- DEPRECATED: OCR feature removed
        ALTER TABLE matches ADD COLUMN ocr_processing_time_ms INTEGER;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'matches' AND column_name = 'ocr_version') THEN
        -- DEPRECATED: OCR feature removed
        ALTER TABLE matches ADD COLUMN ocr_version VARCHAR(20);
    END IF;
END $$;

-- Create indexes for new match columns
CREATE INDEX IF NOT EXISTS idx_matches_event_name ON matches(event_name) WHERE event_name IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_matches_season_year ON matches(season_year) WHERE season_year IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_matches_red_teams ON matches(red_team1, red_team2, red_team3) 
    WHERE red_team1 IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_matches_blue_teams ON matches(blue_team1, blue_team2, blue_team3) 
    WHERE blue_team1 IS NOT NULL;

-- Phase 2: Search performance indexes for Team Explorer
CREATE INDEX IF NOT EXISTS idx_teams_number_search ON teams(number);
CREATE INDEX IF NOT EXISTS idx_teams_name_search ON teams(name);
CREATE INDEX IF NOT EXISTS idx_teams_location_search ON teams(city, state, country);
CREATE INDEX IF NOT EXISTS idx_teams_public ON teams(is_public) WHERE is_public = TRUE;

-- Helper function to populate alliance scores from existing match data
CREATE OR REPLACE FUNCTION populate_alliance_scores()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    -- Populate red_alliance_score from our_score when alliance_color is 'red'
    UPDATE matches
    SET red_alliance_score = our_score
    WHERE alliance_color = 'red' 
      AND our_score IS NOT NULL 
      AND red_alliance_score IS NULL;
    
    -- Populate blue_alliance_score from our_score when alliance_color is 'blue'
    UPDATE matches
    SET blue_alliance_score = our_score
    WHERE alliance_color = 'blue' 
      AND our_score IS NOT NULL 
      AND blue_alliance_score IS NULL;
    
    -- Populate opponent scores
    UPDATE matches
    SET red_alliance_score = opponent_score
    WHERE alliance_color = 'blue' 
      AND opponent_score IS NOT NULL 
      AND red_alliance_score IS NULL;
    
    UPDATE matches
    SET blue_alliance_score = opponent_score
    WHERE alliance_color = 'red' 
      AND opponent_score IS NOT NULL 
      AND blue_alliance_score IS NULL;
END;
$$;

-- Add budget-related columns to orders
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'budget_id') THEN
        ALTER TABLE orders ADD COLUMN budget_id UUID REFERENCES budgets(id) ON DELETE SET NULL;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'budget_category_id') THEN
        ALTER TABLE orders ADD COLUMN budget_category_id UUID;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'expected_delivery_date') THEN
        ALTER TABLE orders ADD COLUMN expected_delivery_date TIMESTAMPTZ;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'actual_delivery_date') THEN
        ALTER TABLE orders ADD COLUMN actual_delivery_date TIMESTAMPTZ;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'receipt_urls') THEN
        ALTER TABLE orders ADD COLUMN receipt_urls JSONB DEFAULT '[]'::jsonb;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'orders' AND column_name = 'budget_id') THEN
        CREATE INDEX IF NOT EXISTS idx_orders_budget_id ON orders(budget_id);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'orders' AND column_name = 'expected_delivery_date') THEN
        CREATE INDEX IF NOT EXISTS idx_orders_expected_delivery ON orders(expected_delivery_date) WHERE expected_delivery_date IS NOT NULL;
    END IF;
END $$;

-- Fix foreign key constraints to ensure ON DELETE CASCADE behavior
-- This fixes the issue where team deletion fails due to missing CASCADE on constraints
DO $$
BEGIN
    -- CRITICAL FIX: Ensure profiles.team_id foreign key has ON DELETE SET NULL
    -- This is essential for team deletion to work properly
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'profiles_team_id_fkey' 
        AND table_name = 'profiles'
    ) THEN
        -- Check if it already has SET NULL
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.referential_constraints rc
            JOIN information_schema.table_constraints tc ON rc.constraint_name = tc.constraint_name
            WHERE tc.constraint_name = 'profiles_team_id_fkey'
            AND rc.delete_rule = 'SET NULL'
        ) THEN
            -- Drop and recreate with SET NULL
            ALTER TABLE profiles 
            DROP CONSTRAINT profiles_team_id_fkey;
            
            ALTER TABLE profiles 
            ADD CONSTRAINT profiles_team_id_fkey 
            FOREIGN KEY (team_id) 
            REFERENCES teams(id) 
            ON DELETE SET NULL;
        END IF;
    END IF;
    
    -- CRITICAL FIX: Ensure events.team_id foreign key has ON DELETE CASCADE
    -- This is essential for team deletion to work properly
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'events_team_id_fkey' 
        AND table_name = 'events'
    ) THEN
        -- Check if it already has CASCADE
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.referential_constraints rc
            JOIN information_schema.table_constraints tc ON rc.constraint_name = tc.constraint_name
            WHERE tc.constraint_name = 'events_team_id_fkey'
            AND rc.delete_rule = 'CASCADE'
        ) THEN
            -- Drop and recreate with CASCADE
            ALTER TABLE events 
            DROP CONSTRAINT events_team_id_fkey;
            
            ALTER TABLE events 
            ADD CONSTRAINT events_team_id_fkey 
            FOREIGN KEY (team_id) 
            REFERENCES teams(id) 
            ON DELETE CASCADE;
        END IF;
    END IF;
    
    -- Fix ALL other team_id foreign key constraints to ensure CASCADE
    -- This prevents foreign key violations when deleting teams
    -- Fix each table individually to ensure all constraints are correct
    DECLARE
        constraint_rec RECORD;
    BEGIN
        FOR constraint_rec IN
            SELECT DISTINCT tc.constraint_name, tc.table_name
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu 
                ON tc.constraint_name = kcu.constraint_name
                AND tc.table_schema = kcu.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY'
            AND kcu.column_name = 'team_id'
            AND tc.table_name != 'profiles'  -- profiles handled separately above
            AND tc.table_schema = 'public'
            AND tc.table_name IN (
                'team_join_requests', 'vendors', 'budgets', 'events', 
                'tasks', 'inventory_items', 'orders', 'scouting_templates',
                'scouting_reports', 'matches', 'troubleshooting_entries'
            )
        LOOP
            -- Check if constraint already has CASCADE
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.referential_constraints rc
                WHERE rc.constraint_name = constraint_rec.constraint_name
                AND rc.constraint_schema = 'public'
                AND rc.delete_rule = 'CASCADE'
            ) THEN
                -- Drop and recreate with CASCADE
                EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', 
                    constraint_rec.table_name, 
                    constraint_rec.constraint_name);
                
                EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE',
                    constraint_rec.table_name,
                    constraint_rec.constraint_name);
            END IF;
        END LOOP;
    END;
    
    -- Fix scouting_templates constraint (explicit check)
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'scouting_templates_team_id_fkey' 
        AND table_name = 'scouting_templates'
    ) THEN
        -- Check if it already has CASCADE
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.referential_constraints rc
            JOIN information_schema.table_constraints tc ON rc.constraint_name = tc.constraint_name
            WHERE tc.constraint_name = 'scouting_templates_team_id_fkey'
            AND rc.delete_rule = 'CASCADE'
        ) THEN
            -- Drop and recreate with CASCADE
            ALTER TABLE scouting_templates 
            DROP CONSTRAINT scouting_templates_team_id_fkey;
            
            ALTER TABLE scouting_templates 
            ADD CONSTRAINT scouting_templates_team_id_fkey 
            FOREIGN KEY (team_id) 
            REFERENCES teams(id) 
            ON DELETE CASCADE;
        END IF;
    END IF;
END $$;

-- ============================================================================
-- Team Deletion Function
-- ============================================================================
-- This function ensures complete team deletion and allows recreating teams
-- with the same info (team number, name, etc.) after deletion.
--
-- DELETION BEHAVIOR:
-- 1. When a team is deleted, ALL related data is completely removed via CASCADE:
--    - team_join_requests (ON DELETE CASCADE)
--    - vendors (ON DELETE CASCADE)
--    - budgets (ON DELETE CASCADE)
--    - events (ON DELETE CASCADE) -> rsvps (ON DELETE CASCADE via events)
--    - tasks (ON DELETE CASCADE) -> task_attachments (ON DELETE CASCADE via tasks)
--    - inventory_items (ON DELETE CASCADE) -> stock_transactions (ON DELETE CASCADE via items)
--    - orders (ON DELETE CASCADE) -> order_items (ON DELETE CASCADE via orders)
--    - scouting_templates (ON DELETE CASCADE)
--    - scouting_reports (ON DELETE CASCADE)
--    - matches (ON DELETE CASCADE)
--    - troubleshooting_entries (ON DELETE CASCADE) -> troubleshooting_attachments (ON DELETE CASCADE)
--
-- 2. User profiles are NOT deleted (profiles.team_id set to NULL via ON DELETE SET NULL)
--    This preserves user accounts while removing team association.
--
-- 3. After deletion, the team number becomes available again (UNIQUE constraint allows reuse)
--    The same person or a different person can create a team with the same number/name.
--
-- 4. All team data is permanently removed - no soft deletes or archives.
-- ============================================================================

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
    
    -- CRITICAL FIX: Remove all members from team FIRST (set team_id and team_role to NULL)
    -- This must happen before deleting the team to avoid foreign key constraint violations
    -- Using SECURITY DEFINER bypasses RLS, so this update will work
    -- NOTE: This update bypasses any leave validation because we're deleting the entire team
    -- The team creator is allowed to delete the team even if they're the last coach
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

-- ============================================================================
-- Function to check if team number already exists (bypasses RLS)
-- ============================================================================
-- This function allows checking team number uniqueness without RLS restrictions
-- Used when creating teams to validate that the team number is available
DROP FUNCTION IF EXISTS public.check_team_number_exists(TEXT) CASCADE;
CREATE OR REPLACE FUNCTION public.check_team_number_exists(p_team_number TEXT)
RETURNS TABLE(number_exists BOOLEAN, existing_team_name VARCHAR)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
    v_number_exists BOOLEAN;
    v_team_name VARCHAR;
BEGIN
    -- Check if team number exists
    SELECT EXISTS(SELECT 1 FROM teams WHERE number = p_team_number) INTO v_number_exists;
    
    -- Get team name if it exists
    IF v_number_exists THEN
        SELECT name INTO v_team_name FROM teams WHERE number = p_team_number LIMIT 1;
    ELSE
        v_team_name := NULL;
    END IF;
    
    -- Return the result
    RETURN QUERY SELECT v_number_exists, v_team_name;
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_team_number_exists(TEXT) TO authenticated, anon;
ALTER FUNCTION public.check_team_number_exists(TEXT) OWNER TO postgres;

-- ============================================================================
-- Phase 2: Public Team Views for Team Explorer
-- ============================================================================

-- View for public team statistics (aggregated across all events/seasons)
-- DEPRECATED: Views removed - using direct table queries instead
-- These views were causing errors due to table structure mismatches
-- The TeamExplorerService now queries teams, team_statistics, and matches tables directly

-- CREATE OR REPLACE VIEW public_team_statistics AS
-- ... (view definition commented out - use direct queries to teams and team_statistics tables)

-- CREATE OR REPLACE VIEW public_team_matches AS
-- ... (view definition commented out - use direct queries to matches table)

-- ============================================================================
-- Team Deletion Summary
-- ============================================================================
-- IMPORTANT: Team deletion behavior is designed to:
--
-- 1. COMPLETE DATA REMOVAL: When a team is deleted, ALL related data is
--    permanently removed via CASCADE constraints. No data remains.
--
-- 2. TEAM NUMBER REUSE: After deletion, the team number becomes available
--    again. The UNIQUE constraint on teams.number allows the same number
--    to be used by a new team (same person or different person).
--
-- 3. USER PRESERVATION: User profiles are NOT deleted. Only the team_id
--    is set to NULL, preserving user accounts.
--
-- 4. NO SOFT DELETES: All deletions are permanent. There are no is_deleted
--    flags or archive tables.
--
-- To delete a team, use the delete_team_completely() function or delete
-- directly from the teams table (CASCADE will handle related data).
-- ============================================================================

-- ============================================================================
-- Setup Complete!
-- ============================================================================
-- Next: Run 02_rls_policies.sql to enable Row Level Security
-- ============================================================================


