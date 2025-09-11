-- Migration: Update Installation Projects Table
-- Date: 2025-09-03
-- Description: Adds missing columns to installation_projects table

-- Add missing columns to installation_projects table if they don't exist
DO $$ 
BEGIN
    -- Add customer_name column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'installation_projects' 
                   AND column_name = 'customer_name') THEN
        ALTER TABLE public.installation_projects 
        ADD COLUMN customer_name VARCHAR(255);
    END IF;

    -- Add customer_address column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'installation_projects' 
                   AND column_name = 'customer_address') THEN
        ALTER TABLE public.installation_projects 
        ADD COLUMN customer_address TEXT;
    END IF;

    -- Add site_latitude column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'installation_projects' 
                   AND column_name = 'site_latitude') THEN
        ALTER TABLE public.installation_projects 
        ADD COLUMN site_latitude DECIMAL(10,8);
    END IF;

    -- Add site_longitude column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'installation_projects' 
                   AND column_name = 'site_longitude') THEN
        ALTER TABLE public.installation_projects 
        ADD COLUMN site_longitude DECIMAL(11,8);
    END IF;
END $$;

-- Update existing records to have default values (you may need to customize this)
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

-- Make the columns NOT NULL after setting default values
ALTER TABLE public.installation_projects 
    ALTER COLUMN customer_name SET NOT NULL,
    ALTER COLUMN customer_address SET NOT NULL,
    ALTER COLUMN site_latitude SET NOT NULL,
    ALTER COLUMN site_longitude SET NOT NULL;

-- Create additional indexes for new columns
CREATE INDEX IF NOT EXISTS idx_installation_projects_customer_name ON public.installation_projects(customer_name);
CREATE INDEX IF NOT EXISTS idx_installation_projects_location ON public.installation_projects(site_latitude, site_longitude);

-- Add comments for the new columns
COMMENT ON COLUMN public.installation_projects.customer_name IS 'Name of the customer for this installation project';
COMMENT ON COLUMN public.installation_projects.customer_address IS 'Full address of the customer installation site';
COMMENT ON COLUMN public.installation_projects.site_latitude IS 'Latitude coordinate of the installation site';
COMMENT ON COLUMN public.installation_projects.site_longitude IS 'Longitude coordinate of the installation site';
