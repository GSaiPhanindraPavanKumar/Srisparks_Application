-- Migration: Add Scheduled Start Date to Installation Projects
-- Date: September 11, 2025
-- Purpose: Add scheduled_start_date column for installation planning and coordination

BEGIN;

-- Add scheduled_start_date column to installation_projects table
ALTER TABLE installation_projects 
ADD COLUMN IF NOT EXISTS scheduled_start_date TIMESTAMPTZ;

-- Add comment to the column for documentation
COMMENT ON COLUMN installation_projects.scheduled_start_date IS 'Planned/scheduled start date for the installation project - used for planning and coordination purposes';

-- Update the installation_project_overview view to include scheduled_start_date
DROP VIEW IF EXISTS installation_project_overview;
CREATE VIEW installation_project_overview AS
SELECT 
    ip.id as project_id,
    ip.customer_id,
    c.name as customer_name,
    c.address as customer_address,
    c.phone_number as customer_phone,
    c.latitude as site_latitude,
    c.longitude as site_longitude,
    o.name as office_name,
    ip.status as project_status,
    ip.assigned_by_id,
    assigned_user.full_name as assigned_by_name,
    ip.assigned_date,
    ip.scheduled_start_date,  -- Include the new scheduled start date
    ip.started_date,
    ip.completed_date,
    ip.notes as project_notes,
    COUNT(iwi.id) as total_work_items,
    COUNT(CASE WHEN iwi.status = 'completed' THEN 1 END) as completed_work_items,
    COUNT(CASE WHEN iwi.verification_status = 'verified' THEN 1 END) as verified_work_items,
    COALESCE(AVG(iwi.progress_percentage), 0) as overall_progress_percentage,
    ip.created_at,
    ip.updated_at
FROM installation_projects ip
JOIN customers c ON ip.customer_id = c.id
LEFT JOIN offices o ON c.office_id = o.id
LEFT JOIN users assigned_user ON ip.assigned_by_id = assigned_user.id
LEFT JOIN installation_work_items iwi ON ip.id = iwi.project_id
GROUP BY ip.id, c.id, c.name, c.address, c.phone_number, c.latitude, c.longitude,
         o.name, assigned_user.full_name, ip.assigned_date, ip.scheduled_start_date,
         ip.started_date, ip.completed_date, ip.notes, ip.created_at, ip.updated_at;

-- Verify the changes
DO $$
BEGIN
    -- Check if column was added successfully
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'installation_projects' 
        AND column_name = 'scheduled_start_date'
    ) THEN
        RAISE NOTICE '✅ Successfully added scheduled_start_date column to installation_projects table';
    ELSE
        RAISE EXCEPTION '❌ Failed to add scheduled_start_date column';
    END IF;

    -- Check if view was updated successfully
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'installation_project_overview' 
        AND column_name = 'scheduled_start_date'
    ) THEN
        RAISE NOTICE '✅ Successfully updated installation_project_overview view';
    ELSE
        RAISE EXCEPTION '❌ Failed to update installation_project_overview view';
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE '🎯 Migration Complete! Installation projects now support scheduled start dates.';
    RAISE NOTICE '';
    RAISE NOTICE '📋 What Changed:';
    RAISE NOTICE '• Added scheduled_start_date column to installation_projects table';
    RAISE NOTICE '• Updated installation_project_overview view to include scheduled dates';
    RAISE NOTICE '• All existing projects will have NULL scheduled_start_date (can be updated later)';
    RAISE NOTICE '';
    RAISE NOTICE '💡 Usage:';
    RAISE NOTICE '• Use this field for planning and coordinating installation schedules';
    RAISE NOTICE '• Directors, Managers, and Leads can now set planned start dates';
    RAISE NOTICE '• The date will be saved when creating new installation assignments';
END $$;

COMMIT;
