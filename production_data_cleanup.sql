-- =====================================
-- Sri Sparks Production Data Cleanup Script
-- =====================================
-- This script truncates all data from Supabase tables while preserving:
-- - Table structure
-- - Indexes
-- - Constraints
-- - Foreign key relationships
-- - Triggers and functions
-- 
-- WARNING: This will permanently delete ALL DATA from ALL TABLES
-- Only run this on production environment for fresh deployment setup
-- =====================================

-- Disable foreign key constraints temporarily to avoid dependency issues
SET session_replication_role = replica;

-- Core Application Tables
TRUNCATE TABLE activity_logs RESTART IDENTITY CASCADE;
TRUNCATE TABLE customers RESTART IDENTITY CASCADE;

-- Work Management Tables  
TRUNCATE TABLE work RESTART IDENTITY CASCADE;

-- Stock and Inventory Management Tables
TRUNCATE TABLE stock_items RESTART IDENTITY CASCADE;
TRUNCATE TABLE stock_log RESTART IDENTITY CASCADE;

-- Material Allocation Tables
TRUNCATE TABLE material_allocations RESTART IDENTITY CASCADE;
TRUNCATE TABLE material_allocation_items RESTART IDENTITY CASCADE;

-- User and Office Management Tables
TRUNCATE TABLE users RESTART IDENTITY CASCADE;
TRUNCATE TABLE offices RESTART IDENTITY CASCADE;

-- Additional Tables (only if they exist in your database)
-- Uncomment the following lines only if these tables exist:

-- TRUNCATE TABLE customer_status_history RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE customer_complaints RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE work_assignments RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE installation_projects RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE installation_projects_v2 RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE installation_work_items RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE installation_work_phases RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE installation_teams RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE installation_activities RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE installation_employee_assignments RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE installation_work_activities RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE installation_material_usage RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE installation_work_sessions RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE installation_location_logs RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE installation_project_overview RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE installation_work_item_details RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE stock_usage_log RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE inventory_components RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE material_allocation_summary RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE attendance RESTART IDENTITY CASCADE;

-- Re-enable foreign key constraints
SET session_replication_role = DEFAULT;

-- =====================================
-- Post-Cleanup Verification
-- =====================================
-- Check if all tables are empty
DO $$
DECLARE
    table_name TEXT;
    row_count INTEGER;
    table_list TEXT[] := ARRAY[
        'activity_logs', 'customers', 'work', 'stock_items', 'stock_log',
        'material_allocations', 'material_allocation_items', 'users', 'offices'
    ];
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'POST-CLEANUP VERIFICATION REPORT';
    RAISE NOTICE '========================================';
    
    FOREACH table_name IN ARRAY table_list
    LOOP
        BEGIN
            EXECUTE format('SELECT COUNT(*) FROM %I', table_name) INTO row_count;
            IF row_count = 0 THEN
                RAISE NOTICE '✅ Table % is empty', table_name;
            ELSE
                RAISE NOTICE '❌ Table % still has % rows', table_name, row_count;
            END IF;
        EXCEPTION
            WHEN undefined_table THEN
                RAISE NOTICE '⚠️  Table % does not exist', table_name;
        END;
    END LOOP;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Cleanup verification completed';
    RAISE NOTICE '========================================';
END $$;

-- =====================================
-- IMPORTANT NOTES:
-- =====================================
-- 1. This script preserves all database structure (tables, columns, constraints, indexes)
-- 2. RESTART IDENTITY resets auto-incrementing sequences to start from 1
-- 3. CASCADE ensures related records are also removed
-- 4. The verification block shows which tables are successfully cleared
-- 5. Make sure to backup your database before running this script
-- 6. Test this script on a development environment first
-- 
-- TO ENABLE ADDITIONAL TABLES:
-- If you have additional tables that weren't included in the main script,
-- uncomment the relevant TRUNCATE statements above and add them to the 
-- verification table_list array below.
-- 
-- SAFE EXECUTION:
-- This version only includes core tables that definitely exist.
-- Additional tables are commented out to prevent errors.
-- =====================================