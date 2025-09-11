-- Fix Installation Projects Table - Add Missing Columns
-- This script safely adds missing columns to existing installation_projects table
-- Run this if you get "column does not exist" errors

-- First, check if the table exists and what columns it has
DO $$ 
DECLARE
    table_exists boolean;
BEGIN
    -- Check if table exists
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'installation_projects'
    ) INTO table_exists;
    
    IF table_exists THEN
        RAISE NOTICE 'installation_projects table exists. Checking columns...';
        
        -- Add customer_name column if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'installation_projects' 
            AND column_name = 'customer_name'
        ) THEN
            ALTER TABLE public.installation_projects 
            ADD COLUMN customer_name VARCHAR(255);
            RAISE NOTICE 'Added customer_name column';
        ELSE
            RAISE NOTICE 'customer_name column already exists';
        END IF;

        -- Add customer_address column if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'installation_projects' 
            AND column_name = 'customer_address'
        ) THEN
            ALTER TABLE public.installation_projects 
            ADD COLUMN customer_address TEXT;
            RAISE NOTICE 'Added customer_address column';
        ELSE
            RAISE NOTICE 'customer_address column already exists';
        END IF;

        -- Add site_latitude column if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'installation_projects' 
            AND column_name = 'site_latitude'
        ) THEN
            ALTER TABLE public.installation_projects 
            ADD COLUMN site_latitude DECIMAL(10,8);
            RAISE NOTICE 'Added site_latitude column';
        ELSE
            RAISE NOTICE 'site_latitude column already exists';
        END IF;

        -- Add site_longitude column if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'installation_projects' 
            AND column_name = 'site_longitude'
        ) THEN
            ALTER TABLE public.installation_projects 
            ADD COLUMN site_longitude DECIMAL(11,8);
            RAISE NOTICE 'Added site_longitude column';
        ELSE
            RAISE NOTICE 'site_longitude column already exists';
        END IF;

        -- Update any existing records with default values
        UPDATE public.installation_projects 
        SET 
            customer_name = COALESCE(customer_name, 'Unknown Customer'),
            customer_address = COALESCE(customer_address, 'Address Not Provided'),
            site_latitude = COALESCE(site_latitude, 0.0),
            site_longitude = COALESCE(site_longitude, 0.0)
        WHERE customer_name IS NULL 
           OR customer_address IS NULL 
           OR site_latitude IS NULL 
           OR site_longitude IS NULL;

        RAISE NOTICE 'Updated existing records with default values';

        -- Make the columns NOT NULL after setting default values
        BEGIN
            ALTER TABLE public.installation_projects 
                ALTER COLUMN customer_name SET NOT NULL;
            RAISE NOTICE 'Set customer_name as NOT NULL';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'customer_name column may already be NOT NULL';
        END;

        BEGIN
            ALTER TABLE public.installation_projects 
                ALTER COLUMN customer_address SET NOT NULL;
            RAISE NOTICE 'Set customer_address as NOT NULL';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'customer_address column may already be NOT NULL';
        END;

        BEGIN
            ALTER TABLE public.installation_projects 
                ALTER COLUMN site_latitude SET NOT NULL;
            RAISE NOTICE 'Set site_latitude as NOT NULL';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'site_latitude column may already be NOT NULL';
        END;

        BEGIN
            ALTER TABLE public.installation_projects 
                ALTER COLUMN site_longitude SET NOT NULL;
            RAISE NOTICE 'Set site_longitude as NOT NULL';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'site_longitude column may already be NOT NULL';
        END;

        -- Create indexes for new columns
        CREATE INDEX IF NOT EXISTS idx_installation_projects_customer_name 
            ON public.installation_projects(customer_name);
        
        CREATE INDEX IF NOT EXISTS idx_installation_projects_location 
            ON public.installation_projects(site_latitude, site_longitude);
        
        RAISE NOTICE 'Created indexes for new columns';
        
    ELSE
        RAISE NOTICE 'installation_projects table does not exist. Please run the main migration script first.';
    END IF;
END $$;

-- Add comments for the new columns
COMMENT ON COLUMN public.installation_projects.customer_name IS 'Name of the customer for this installation project';
COMMENT ON COLUMN public.installation_projects.customer_address IS 'Full address of the customer installation site';
COMMENT ON COLUMN public.installation_projects.site_latitude IS 'Latitude coordinate of the installation site';
COMMENT ON COLUMN public.installation_projects.site_longitude IS 'Longitude coordinate of the installation site';

-- Verify the columns exist for both tables
SELECT 'installation_projects columns:' as table_info;
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'installation_projects'
ORDER BY ordinal_position;

SELECT 'installation_work_items columns:' as table_info;
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'installation_work_items'
ORDER BY ordinal_position;
