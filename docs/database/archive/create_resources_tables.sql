-- Migration: Create resources tables for Phase 5
-- This migration creates tables for storing FTC educational resources

-- Main resources table
CREATE TABLE IF NOT EXISTS resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    explanation TEXT,
    url TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('official', 'rules', 'community', 'technical', 'programming', 'strategy', 'safety', 'awards', 'video', 'parts')),
    icon TEXT NOT NULL,
    view_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Resource subpages table
CREATE TABLE IF NOT EXISTS resource_subpages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    url TEXT NOT NULL,
    description TEXT NOT NULL,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(resource_id, title)
);

-- User bookmarks/favorites table
CREATE TABLE IF NOT EXISTS user_resource_bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, resource_id)
);

-- User resource progress tracking
CREATE TABLE IF NOT EXISTS user_resource_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT FALSE,
    is_completed BOOLEAN DEFAULT FALSE,
    last_viewed_at TIMESTAMPTZ,
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, resource_id)
);

-- Recent searches table
CREATE TABLE IF NOT EXISTS user_recent_searches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    search_query TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, search_query)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_resources_category ON resources(category);
CREATE INDEX IF NOT EXISTS idx_resources_view_count ON resources(view_count DESC);
CREATE INDEX IF NOT EXISTS idx_resource_subpages_resource_id ON resource_subpages(resource_id);
CREATE INDEX IF NOT EXISTS idx_user_resource_bookmarks_user_id ON user_resource_bookmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_user_resource_bookmarks_resource_id ON user_resource_bookmarks(resource_id);
CREATE INDEX IF NOT EXISTS idx_user_resource_progress_user_id ON user_resource_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_resource_progress_resource_id ON user_resource_progress(resource_id);
CREATE INDEX IF NOT EXISTS idx_user_recent_searches_user_id ON user_recent_searches(user_id);
CREATE INDEX IF NOT EXISTS idx_user_recent_searches_created_at ON user_recent_searches(created_at DESC);

-- Full-text search index (PostgreSQL)
CREATE INDEX IF NOT EXISTS idx_resources_search ON resources USING gin(to_tsvector('english', title || ' ' || description || COALESCE(explanation, '')));

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to auto-update updated_at (drop if exists to allow re-running migration)
DROP TRIGGER IF EXISTS update_resources_updated_at ON resources;
CREATE TRIGGER update_resources_updated_at BEFORE UPDATE ON resources
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_resource_progress_updated_at ON user_resource_progress;
CREATE TRIGGER update_user_resource_progress_updated_at BEFORE UPDATE ON user_resource_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) policies
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE resource_subpages ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_resource_bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_resource_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_recent_searches ENABLE ROW LEVEL SECURITY;

-- Resources are publicly readable (drop if exists to allow re-running migration)
DROP POLICY IF EXISTS "Resources are publicly readable" ON resources;
CREATE POLICY "Resources are publicly readable" ON resources
    FOR SELECT USING (true);

-- Resources can be inserted by anyone (for syncing resources from app)
DROP POLICY IF EXISTS "Resources are publicly insertable" ON resources;
CREATE POLICY "Resources are publicly insertable" ON resources
    FOR INSERT WITH CHECK (true);

-- Resources view_count can be updated by anyone (for tracking)
DROP POLICY IF EXISTS "Resources view_count is publicly updatable" ON resources;
CREATE POLICY "Resources view_count is publicly updatable" ON resources
    FOR UPDATE USING (true)
    WITH CHECK (true);

-- Resource subpages are publicly readable
DROP POLICY IF EXISTS "Resource subpages are publicly readable" ON resource_subpages;
CREATE POLICY "Resource subpages are publicly readable" ON resource_subpages
    FOR SELECT USING (true);

-- Resource subpages can be inserted by anyone (for syncing subpages from app)
DROP POLICY IF EXISTS "Resource subpages are publicly insertable" ON resource_subpages;
CREATE POLICY "Resource subpages are publicly insertable" ON resource_subpages
    FOR INSERT WITH CHECK (true);

-- Users can manage their own bookmarks (drop if exists to allow re-running migration)
DROP POLICY IF EXISTS "Users can view their own bookmarks" ON user_resource_bookmarks;
CREATE POLICY "Users can view their own bookmarks" ON user_resource_bookmarks
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create their own bookmarks" ON user_resource_bookmarks;
CREATE POLICY "Users can create their own bookmarks" ON user_resource_bookmarks
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own bookmarks" ON user_resource_bookmarks;
CREATE POLICY "Users can delete their own bookmarks" ON user_resource_bookmarks
    FOR DELETE USING (auth.uid() = user_id);

-- Users can manage their own progress
DROP POLICY IF EXISTS "Users can view their own progress" ON user_resource_progress;
CREATE POLICY "Users can view their own progress" ON user_resource_progress
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create their own progress" ON user_resource_progress;
CREATE POLICY "Users can create their own progress" ON user_resource_progress
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own progress" ON user_resource_progress;
CREATE POLICY "Users can update their own progress" ON user_resource_progress
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can manage their own recent searches
DROP POLICY IF EXISTS "Users can view their own recent searches" ON user_recent_searches;
CREATE POLICY "Users can view their own recent searches" ON user_recent_searches
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create their own recent searches" ON user_recent_searches;
CREATE POLICY "Users can create their own recent searches" ON user_recent_searches
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own recent searches" ON user_recent_searches;
CREATE POLICY "Users can delete their own recent searches" ON user_recent_searches
    FOR DELETE USING (auth.uid() = user_id);

-- RPC Function to increment view count
CREATE OR REPLACE FUNCTION increment_resource_view_count(resource_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE resources
    SET view_count = view_count + 1
    WHERE id = resource_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

