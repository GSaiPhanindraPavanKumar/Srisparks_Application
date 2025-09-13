-- Migration: Add installation_project_id column to customers table
-- This migration adds a reference to the installation project in the customer record

-- Add installation_project_id column to customers table
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS installation_project_id UUID REFERENCES installation_projects(id);

-- Add comment for documentation
COMMENT ON COLUMN customers.installation_project_id IS 'Reference to the installation project assigned to this customer';

-- Create index for better performance when querying by installation project
CREATE INDEX IF NOT EXISTS idx_customers_installation_project_id 
ON customers(installation_project_id);

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Successfully added installation_project_id column to customers table!';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Changes Made:';
    RAISE NOTICE '• Added installation_project_id column as UUID with foreign key to installation_projects';
    RAISE NOTICE '• Added index for performance optimization';
    RAISE NOTICE '• Column allows NULL values (existing customers without installation projects)';
    RAISE NOTICE '';
    RAISE NOTICE '🔗 Relationship:';
    RAISE NOTICE '• customers.installation_project_id → installation_projects.id';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Usage:';
    RAISE NOTICE '• When creating installation project, update customer with project ID';
    RAISE NOTICE '• Allows easy lookup of customer from installation project and vice versa';
    RAISE NOTICE '• Maintains referential integrity between customers and installation projects';
END $$;