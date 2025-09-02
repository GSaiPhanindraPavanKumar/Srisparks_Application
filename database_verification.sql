-- Database verification script for customer application functionality
-- Run this in your Supabase SQL Editor to verify all required fields exist

-- Check if customers table exists and has all required columns
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'customers' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verify specific application phase columns exist
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customers' AND column_name = 'current_phase') 
        THEN 'current_phase: EXISTS'
        ELSE 'current_phase: MISSING'
    END as current_phase_status,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customers' AND column_name = 'application_date') 
        THEN 'application_date: EXISTS'
        ELSE 'application_date: MISSING'
    END as application_date_status,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customers' AND column_name = 'application_status') 
        THEN 'application_status: EXISTS'
        ELSE 'application_status: MISSING'
    END as application_status_status,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customers' AND column_name = 'manager_recommendation') 
        THEN 'manager_recommendation: EXISTS'
        ELSE 'manager_recommendation: MISSING'
    END as manager_recommendation_status,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customers' AND column_name = 'electric_meter_service_number') 
        THEN 'electric_meter_service_number: EXISTS'
        ELSE 'electric_meter_service_number: MISSING'
    END as service_number_status;

-- Test insert a sample customer record to verify all fields work
-- (This will be rolled back, just for testing)
BEGIN;

INSERT INTO customers (
    name, 
    phone_number, 
    address, 
    city, 
    state, 
    country,
    is_active,
    office_id,
    added_by_id,
    current_phase,
    application_date,
    application_status,
    site_survey_completed,
    feasibility_status
) VALUES (
    'Test Customer',
    '123-456-7890',
    '123 Test St',
    'Test City',
    'Test State',
    'Test Country',
    true,
    (SELECT id FROM offices LIMIT 1), -- Use first available office
    (SELECT id FROM users WHERE role = 'manager' LIMIT 1), -- Use first available manager
    'application',
    NOW(),
    'pending',
    false,
    'pending'
);

SELECT 'Test insert successful - all required fields are working' as test_result;

ROLLBACK; -- Don't actually save the test record

-- Check table constraints
SELECT 
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'customers' 
AND table_schema = 'public';

SELECT 'Database verification complete' as final_status;
