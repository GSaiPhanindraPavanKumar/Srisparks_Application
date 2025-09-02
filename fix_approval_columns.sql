-- Quick fix for approved_by_id column issue
-- Run this in your Supabase SQL Editor to fix the approval functionality

-- The migration script already has the correct column names, but let's verify they exist
-- and add indexes if missing

-- Verify application approval columns exist
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customers' AND column_name = 'application_approved_by_id') 
        THEN 'application_approved_by_id: EXISTS'
        ELSE 'application_approved_by_id: MISSING'
    END as approved_by_status,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customers' AND column_name = 'application_approval_date') 
        THEN 'application_approval_date: EXISTS'
        ELSE 'application_approval_date: MISSING'
    END as approval_date_status,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customers' AND column_name = 'application_notes') 
        THEN 'application_notes: EXISTS'
        ELSE 'application_notes: MISSING'
    END as notes_status;

-- Add missing indexes for application approval fields if they don't exist
CREATE INDEX IF NOT EXISTS idx_customers_application_approved_by_id ON customers(application_approved_by_id);
CREATE INDEX IF NOT EXISTS idx_customers_application_approval_date ON customers(application_approval_date);

-- Show current table structure for application fields
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'customers' 
AND column_name LIKE 'application_%'
AND table_schema = 'public'
ORDER BY column_name;

SELECT 'Application approval fields verification complete' as result;
