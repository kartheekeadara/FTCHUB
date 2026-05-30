-- Safety & Compliance Tables
-- Run this SQL in your Supabase SQL Editor

-- Consent Records table
CREATE TABLE IF NOT EXISTS consent_records (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    student_id UUID REFERENCES profiles(id) NOT NULL,
    parent_name VARCHAR(255) NOT NULL,
    parent_email VARCHAR(255) NOT NULL,
    parent_phone VARCHAR(20),
    relationship VARCHAR(50) NOT NULL,
    consent_type VARCHAR(50) NOT NULL,
    consent_given BOOLEAN DEFAULT FALSE,
    consent_date TIMESTAMP WITH TIME ZONE,
    expiration_date TIMESTAMP WITH TIME ZONE,
    signature TEXT,
    ip_address VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Emergency Contacts table
CREATE TABLE IF NOT EXISTS emergency_contacts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    student_id UUID REFERENCES profiles(id) NOT NULL,
    name VARCHAR(255) NOT NULL,
    relationship VARCHAR(100) NOT NULL,
    primary_phone VARCHAR(20) NOT NULL,
    alternate_phone VARCHAR(20),
    email VARCHAR(255),
    address TEXT,
    is_primary BOOLEAN DEFAULT FALSE,
    can_pickup BOOLEAN DEFAULT FALSE,
    medical_conditions TEXT,
    allergies TEXT,
    medications TEXT,
    insurance JSONB, -- Store insurance info as JSON
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_consent_records_student_id ON consent_records(student_id);
CREATE INDEX IF NOT EXISTS idx_consent_records_consent_type ON consent_records(consent_type);
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_student_id ON emergency_contacts(student_id);
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_is_primary ON emergency_contacts(is_primary);

-- Create updated_at triggers
CREATE TRIGGER update_consent_records_updated_at 
    BEFORE UPDATE ON consent_records 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_emergency_contacts_updated_at 
    BEFORE UPDATE ON emergency_contacts 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE consent_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for consent_records
CREATE POLICY "Users can view consent records for their team members" 
    ON consent_records FOR SELECT 
    USING (
        student_id IN (
            SELECT p.id FROM profiles p 
            WHERE p.team_id IN (
                SELECT team_id FROM profiles WHERE id = auth.uid()
            )
        )
    );

CREATE POLICY "Admins can insert consent records" 
    ON consent_records FOR INSERT 
    WITH CHECK (
        student_id IN (
            SELECT p.id FROM profiles p 
            WHERE p.team_id IN (
                SELECT team_id FROM profiles WHERE id = auth.uid() AND role = 'admin'
            )
        )
    );

CREATE POLICY "Admins can update consent records" 
    ON consent_records FOR UPDATE 
    USING (
        student_id IN (
            SELECT p.id FROM profiles p 
            WHERE p.team_id IN (
                SELECT team_id FROM profiles WHERE id = auth.uid() AND role = 'admin'
            )
        )
    );

-- Create RLS policies for emergency_contacts
CREATE POLICY "Users can view emergency contacts for their team members" 
    ON emergency_contacts FOR SELECT 
    USING (
        student_id IN (
            SELECT p.id FROM profiles p 
            WHERE p.team_id IN (
                SELECT team_id FROM profiles WHERE id = auth.uid()
            )
        )
    );

CREATE POLICY "Admins can manage emergency contacts" 
    ON emergency_contacts FOR ALL 
    USING (
        student_id IN (
            SELECT p.id FROM profiles p 
            WHERE p.team_id IN (
                SELECT team_id FROM profiles WHERE id = auth.uid() AND role = 'admin'
            )
        )
    );

