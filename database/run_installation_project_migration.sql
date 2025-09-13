-- Add installation_project_id column to customers table migration
-- Run this script to add the installation project reference to customers

-- Execute the migration
\i 'database/add_installation_project_id_to_customers.sql'

-- Verify the changes
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'customers' 
  AND column_name = 'installation_project_id';

-- Check if index was created
SELECT indexname, indexdef
FROM pg_indexes 
WHERE tablename = 'customers' 
  AND indexname = 'idx_customers_installation_project_id';