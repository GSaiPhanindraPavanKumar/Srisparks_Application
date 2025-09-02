-- Migration script to add manager recommendation fields to customers table
-- Run this in your Supabase SQL Editor

-- Add missing current_phase column first (required for application phase functionality)
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS current_phase TEXT DEFAULT 'application' CHECK (current_phase IN (
  'application', 'amount', 'material_allocation', 'material_delivery', 
  'installation', 'documentation', 'meter_connection', 
  'inverter_turnon', 'completed', 'service_phase'
));

-- Add application phase fields if they don't exist
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS application_date TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS application_details JSONB,
ADD COLUMN IF NOT EXISTS application_status TEXT DEFAULT 'pending' CHECK (application_status IN ('pending', 'approved', 'rejected')),
ADD COLUMN IF NOT EXISTS application_approved_by_id UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS application_approval_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS application_notes TEXT;

-- Add manager recommendation fields to customers table
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS manager_recommendation TEXT CHECK (manager_recommendation IN ('approve', 'reject')),
ADD COLUMN IF NOT EXISTS manager_recommended_by_id UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS manager_recommendation_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS manager_recommendation_comment TEXT;

-- Add site survey and feasibility fields
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS site_survey_completed BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS site_survey_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS site_survey_technician_id UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS site_survey_photos JSONB,
ADD COLUMN IF NOT EXISTS estimated_kw INTEGER,
ADD COLUMN IF NOT EXISTS estimated_cost DECIMAL(12,2),
ADD COLUMN IF NOT EXISTS feasibility_status TEXT DEFAULT 'pending' CHECK (feasibility_status IN ('pending', 'feasible', 'not_feasible'));

-- Add equipment serial number fields
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS solar_panels_serial_numbers TEXT,
ADD COLUMN IF NOT EXISTS inverter_serial_numbers TEXT,
ADD COLUMN IF NOT EXISTS electric_meter_service_number TEXT;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_customers_current_phase ON customers(current_phase);
CREATE INDEX IF NOT EXISTS idx_customers_application_status ON customers(application_status);
CREATE INDEX IF NOT EXISTS idx_customers_application_date ON customers(application_date);
CREATE INDEX IF NOT EXISTS idx_customers_application_approved_by_id ON customers(application_approved_by_id);
CREATE INDEX IF NOT EXISTS idx_customers_application_approval_date ON customers(application_approval_date);
CREATE INDEX IF NOT EXISTS idx_customers_manager_recommendation ON customers(manager_recommendation);
CREATE INDEX IF NOT EXISTS idx_customers_manager_recommended_by_id ON customers(manager_recommended_by_id);
CREATE INDEX IF NOT EXISTS idx_customers_manager_recommendation_date ON customers(manager_recommendation_date);
CREATE INDEX IF NOT EXISTS idx_customers_site_survey_completed ON customers(site_survey_completed);
CREATE INDEX IF NOT EXISTS idx_customers_feasibility_status ON customers(feasibility_status);

-- Update existing customers table comment
COMMENT ON TABLE customers IS 'Customer information and solar installation project lifecycle with manager recommendation support';

-- Add comments for new fields
COMMENT ON COLUMN customers.current_phase IS 'Current phase of the solar installation project';
COMMENT ON COLUMN customers.application_date IS 'Date when application was submitted';
COMMENT ON COLUMN customers.application_status IS 'Status of the application: pending, approved, rejected';
COMMENT ON COLUMN customers.manager_recommendation IS 'Manager recommendation: approve or reject';
COMMENT ON COLUMN customers.manager_recommended_by_id IS 'ID of the manager who provided the recommendation';
COMMENT ON COLUMN customers.manager_recommendation_date IS 'Date when manager recommendation was provided';
COMMENT ON COLUMN customers.manager_recommendation_comment IS 'Optional comment from manager with recommendation';
COMMENT ON COLUMN customers.site_survey_completed IS 'Whether site survey has been completed';
COMMENT ON COLUMN customers.feasibility_status IS 'Feasibility assessment status';
COMMENT ON COLUMN customers.electric_meter_service_number IS 'Electric meter service number for the property';
