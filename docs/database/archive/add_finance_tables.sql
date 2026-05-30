-- Financial Management System Tables
-- Run this SQL in your Supabase SQL Editor

-- Vendors table
CREATE TABLE IF NOT EXISTS vendors (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    team_id UUID REFERENCES teams(id) NOT NULL,
    name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    website TEXT,
    address TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Budgets table
CREATE TABLE IF NOT EXISTS budgets (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    team_id UUID REFERENCES teams(id) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    total_amount DECIMAL(10,2) NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    categories JSONB NOT NULL, -- Store budget categories as JSON
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_vendors_team_id ON vendors(team_id);
CREATE INDEX IF NOT EXISTS idx_budgets_team_id ON budgets(team_id);
CREATE INDEX IF NOT EXISTS idx_orders_team_id ON orders(team_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

-- Create updated_at triggers
CREATE TRIGGER update_vendors_updated_at 
    BEFORE UPDATE ON vendors 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budgets_updated_at 
    BEFORE UPDATE ON budgets 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for vendors
CREATE POLICY "Users can view vendors from their team" 
    ON vendors FOR SELECT 
    USING (team_id IN (SELECT team_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can insert vendors for their team" 
    ON vendors FOR INSERT 
    WITH CHECK (team_id IN (SELECT team_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can update vendors from their team" 
    ON vendors FOR UPDATE 
    USING (team_id IN (SELECT team_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can delete vendors from their team" 
    ON vendors FOR DELETE 
    USING (team_id IN (SELECT team_id FROM profiles WHERE id = auth.uid()));

-- Create RLS policies for budgets
CREATE POLICY "Users can view budgets from their team" 
    ON budgets FOR SELECT 
    USING (team_id IN (SELECT team_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can insert budgets for their team" 
    ON budgets FOR INSERT 
    WITH CHECK (team_id IN (SELECT team_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can update budgets from their team" 
    ON budgets FOR UPDATE 
    USING (team_id IN (SELECT team_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can delete budgets from their team" 
    ON budgets FOR DELETE 
    USING (team_id IN (SELECT team_id FROM profiles WHERE id = auth.uid()));

