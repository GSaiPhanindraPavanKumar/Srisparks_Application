-- Complete Database Schema for SriSparks Application
-- This script recreates the entire database structure for a new Supabase project

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create ENUM types first
CREATE TYPE user_role AS ENUM ('director', 'manager', 'lead', 'employee');
CREATE TYPE user_status AS ENUM ('active', 'inactive');
CREATE TYPE approval_status AS ENUM ('pending', 'approved', 'rejected');

-- 1. Offices Table
CREATE TABLE public.offices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT,
    city TEXT,
    state TEXT,
    zip_code TEXT,
    country TEXT,
    phone_number TEXT,
    email TEXT,
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    metadata JSONB
);

-- 2. Users Table
CREATE TABLE public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    phone_number TEXT,
    role user_role NOT NULL DEFAULT 'employee',
    status user_status NOT NULL DEFAULT 'active',
    is_lead BOOLEAN DEFAULT false,
    office_id UUID REFERENCES offices(id),
    added_by UUID REFERENCES users(id),
    added_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
    approved_by UUID REFERENCES users(id),
    approved_time TIMESTAMP WITH TIME ZONE,
    approval_status approval_status DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    metadata JSONB
);

-- 3. Installation Projects Table
CREATE TABLE public.installation_projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_name TEXT NOT NULL,
    customer_name TEXT NOT NULL,
    location TEXT,
    project_manager_id UUID REFERENCES users(id),
    status TEXT DEFAULT 'planning',
    start_date DATE,
    estimated_completion_date DATE,
    actual_completion_date DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 4. Customers Table (Main table with all phases)
CREATE TABLE public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT,
    phone_number TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    zip_code TEXT,
    country TEXT,
    is_active BOOLEAN DEFAULT true,
    office_id UUID NOT NULL REFERENCES offices(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    metadata JSONB,
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8),
    kw INTEGER,
    added_by_id UUID NOT NULL REFERENCES users(id),
    
    -- Application Phase
    application_date TIMESTAMP WITH TIME ZONE DEFAULT now(),
    application_details JSONB,
    application_status TEXT DEFAULT 'pending' CHECK (application_status IN ('pending', 'approved', 'rejected')),
    application_approved_by_id UUID REFERENCES users(id),
    application_approval_date TIMESTAMP WITH TIME ZONE,
    application_notes TEXT,
    
    -- Site Survey
    site_survey_completed BOOLEAN DEFAULT false,
    site_survey_date TIMESTAMP WITH TIME ZONE,
    site_survey_technician_id UUID REFERENCES users(id),
    site_survey_photos JSONB,
    estimated_kw INTEGER,
    estimated_cost NUMERIC(12, 2),
    feasibility_status TEXT DEFAULT 'pending' CHECK (feasibility_status IN ('pending', 'feasible', 'not_feasible')),
    
    -- Equipment Serial Numbers
    solar_panels_serial_numbers TEXT,
    inverter_serial_numbers TEXT,
    electric_meter_service_number TEXT,
    
    -- Manager Recommendation
    manager_recommendation TEXT CHECK (manager_recommendation IN ('approve', 'reject')),
    manager_recommended_by_id UUID REFERENCES users(id),
    manager_recommendation_date TIMESTAMP WITH TIME ZONE,
    manager_recommendation_comment TEXT,
    
    -- Current Phase Tracking
    current_phase TEXT DEFAULT 'application' CHECK (current_phase IN 
        ('application', 'amount', 'material_allocation', 'material_delivery', 
         'installation', 'documentation', 'meter_connection', 'inverter_turnon', 
         'completed', 'service_phase')),
    
    -- Amount Phase
    amount_kw INTEGER,
    amount_total NUMERIC(12, 2),
    amount_paid NUMERIC(12, 2),
    amount_paid_date TIMESTAMP WITH TIME ZONE,
    amount_utr_number TEXT,
    amount_payment_status TEXT DEFAULT 'pending' CHECK (amount_payment_status IN ('pending', 'partial', 'completed')),
    amount_cleared_by_id UUID REFERENCES users(id),
    amount_cleared_date TIMESTAMP WITH TIME ZONE,
    amount_notes TEXT,
    amount_payments_data TEXT,
    phase_updated_date TIMESTAMP WITH TIME ZONE,
    
    -- Material Allocation Phase
    material_allocation_plan TEXT,
    material_allocation_status TEXT DEFAULT 'pending' CHECK (material_allocation_status IN 
        ('pending', 'planned', 'allocated', 'confirmed')),
    material_allocation_date TIMESTAMP WITH TIME ZONE,
    material_allocated_by_id UUID REFERENCES users(id),
    material_allocation_notes TEXT,
    material_planned_by_id UUID REFERENCES users(id),
    material_planned_date TIMESTAMP WITH TIME ZONE,
    material_confirmed_by_id UUID REFERENCES users(id),
    material_confirmed_date TIMESTAMP WITH TIME ZONE,
    material_allocation_history JSONB DEFAULT '[]',
    
    -- Installation Project Reference
    installation_project_id UUID REFERENCES installation_projects(id),
    
    -- Documentation Phase
    documentation_submission_date TIMESTAMP WITHOUT TIME ZONE,
    document_submitted_by UUID REFERENCES users(id),
    documentation_updated_by UUID REFERENCES users(id),
    documentation_updated_timestamp TIMESTAMP WITHOUT TIME ZONE,
    
    -- Meter Connection Phase
    date_of_meter TIMESTAMP WITHOUT TIME ZONE,
    meter_updated_by UUID REFERENCES users(id),
    meter_updated_time TIMESTAMP WITHOUT TIME ZONE,
    
    -- Inverter Turn-on Phase
    date_of_inverter TIMESTAMP WITHOUT TIME ZONE,
    inverter_updated_by UUID REFERENCES users(id),
    inverter_updated_time TIMESTAMP WITHOUT TIME ZONE,
    
    -- Constraints
    CONSTRAINT valid_amount_payments_data CHECK (
        (amount_payments_data IS NULL) OR 
        ((amount_payments_data)::jsonb IS NOT NULL)
    )
);

-- 5. Attendance Table
CREATE TABLE public.attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    office_id UUID NOT NULL REFERENCES offices(id),
    check_in_time TIMESTAMP WITH TIME ZONE NOT NULL,
    check_out_time TIMESTAMP WITH TIME ZONE,
    check_in_location TEXT,
    check_out_location TEXT,
    total_hours NUMERIC(4, 2),
    status TEXT DEFAULT 'present',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 6. Activity Logs Table
CREATE TABLE public.activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    activity_type TEXT NOT NULL,
    description TEXT NOT NULL,
    entity_id UUID,
    entity_type TEXT,
    old_data JSONB,
    new_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create Indexes for Performance
CREATE INDEX idx_users_office_id ON users(office_id);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_approval_status ON users(approval_status);

CREATE INDEX idx_customers_office_id ON customers(office_id);
CREATE INDEX idx_customers_current_phase ON customers(current_phase);
CREATE INDEX idx_customers_application_status ON customers(application_status);
CREATE INDEX idx_customers_amount_payment_status ON customers(amount_payment_status);
CREATE INDEX idx_customers_material_allocation_status ON customers(material_allocation_status);
CREATE INDEX idx_customers_added_by_id ON customers(added_by_id);

CREATE INDEX idx_attendance_user_id ON attendance(user_id);
CREATE INDEX idx_attendance_office_id ON attendance(office_id);
CREATE INDEX idx_attendance_check_in_time ON attendance(check_in_time);

CREATE INDEX idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX idx_activity_logs_entity_type ON activity_logs(entity_type);
CREATE INDEX idx_activity_logs_created_at ON activity_logs(created_at);

-- Create Functions
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create Triggers
CREATE TRIGGER update_offices_updated_at 
    BEFORE UPDATE ON offices 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at 
    BEFORE UPDATE ON customers 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_attendance_updated_at 
    BEFORE UPDATE ON attendance 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE offices ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE installation_projects ENABLE ROW LEVEL SECURITY;

-- Create basic RLS policies (you may need to adjust based on your auth setup)
CREATE POLICY "Users can view their own data" ON users FOR ALL USING (auth.uid()::text = id::text);
CREATE POLICY "Authenticated users can view offices" ON offices FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can view customers" ON customers FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Users can view their own attendance" ON attendance FOR ALL USING (auth.uid()::text = user_id::text);

-- Insert initial data (optional)
-- You can add sample offices, users, etc. here

COMMENT ON TABLE customers IS 'Main customers table tracking all project phases from application to completion';
COMMENT ON COLUMN customers.current_phase IS 'Tracks the current phase of the customer project lifecycle';
COMMENT ON COLUMN customers.material_allocation_history IS 'JSON array storing the complete history of material allocation changes';