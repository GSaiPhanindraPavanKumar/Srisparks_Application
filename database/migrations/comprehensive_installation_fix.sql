-- Comprehensive Fix for Installation Tables Schema Issues
-- This script ensures all installation tables have the correct columns and relationships

DO $$ 
DECLARE
    projects_table_exists boolean;
    work_items_table_exists boolean;
BEGIN
    -- Check if tables exist
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'installation_projects'
    ) INTO projects_table_exists;
    
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'installation_work_items'
    ) INTO work_items_table_exists;
    
    RAISE NOTICE 'Projects table exists: %', projects_table_exists;
    RAISE NOTICE 'Work items table exists: %', work_items_table_exists;
    
    -- Fix installation_projects table
    IF projects_table_exists THEN
        RAISE NOTICE 'Fixing installation_projects table...';
        
        -- Add missing columns for installation_projects
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_schema = 'public' AND table_name = 'installation_projects' 
                       AND column_name = 'customer_name') THEN
            ALTER TABLE public.installation_projects ADD COLUMN customer_name VARCHAR(255);
            RAISE NOTICE 'Added customer_name column to installation_projects';
        END IF;

        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_schema = 'public' AND table_name = 'installation_projects' 
                       AND column_name = 'customer_address') THEN
            ALTER TABLE public.installation_projects ADD COLUMN customer_address TEXT;
            RAISE NOTICE 'Added customer_address column to installation_projects';
        END IF;

        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_schema = 'public' AND table_name = 'installation_projects' 
                       AND column_name = 'site_latitude') THEN
            ALTER TABLE public.installation_projects ADD COLUMN site_latitude DECIMAL(10,8);
            RAISE NOTICE 'Added site_latitude column to installation_projects';
        END IF;

        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_schema = 'public' AND table_name = 'installation_projects' 
                       AND column_name = 'site_longitude') THEN
            ALTER TABLE public.installation_projects ADD COLUMN site_longitude DECIMAL(11,8);
            RAISE NOTICE 'Added site_longitude column to installation_projects';
        END IF;

        -- Update existing records with default values
        UPDATE public.installation_projects 
        SET 
            customer_name = COALESCE(customer_name, 'Unknown Customer'),
            customer_address = COALESCE(customer_address, 'Address Not Provided'),
            site_latitude = COALESCE(site_latitude, 0.0),
            site_longitude = COALESCE(site_longitude, 0.0)
        WHERE customer_name IS NULL OR customer_address IS NULL 
           OR site_latitude IS NULL OR site_longitude IS NULL;
           
        RAISE NOTICE 'Updated installation_projects records with default values';
    END IF;
    
    -- Fix installation_work_items table
    IF work_items_table_exists THEN
        RAISE NOTICE 'Checking installation_work_items table...';
        
        -- Ensure project_id column exists (should already exist but let's verify)
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_schema = 'public' AND table_name = 'installation_work_items' 
                       AND column_name = 'project_id') THEN
            ALTER TABLE public.installation_work_items 
            ADD COLUMN project_id UUID REFERENCES public.installation_projects(id) ON DELETE CASCADE;
            RAISE NOTICE 'Added project_id column to installation_work_items';
        ELSE
            RAISE NOTICE 'project_id column already exists in installation_work_items';
        END IF;
        
        -- Check if customer_id column exists (it shouldn't, but if it does, we need to handle it)
        IF EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'installation_work_items' 
                   AND column_name = 'customer_id') THEN
            RAISE NOTICE 'WARNING: customer_id column found in installation_work_items table';
            RAISE NOTICE 'This column should not exist. Consider running the recreate script.';
        ELSE
            RAISE NOTICE 'Correct: customer_id column does not exist in installation_work_items';
        END IF;
        
        -- Ensure other essential columns exist
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_schema = 'public' AND table_name = 'installation_work_items' 
                       AND column_name = 'work_type') THEN
            ALTER TABLE public.installation_work_items 
            ADD COLUMN work_type VARCHAR(50) NOT NULL DEFAULT 'structure_work' 
            CHECK (work_type IN ('structure_work', 'panels', 'inverter_wiring', 'earthing', 'lightning_arrestor'));
            RAISE NOTICE 'Added work_type column to installation_work_items';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_schema = 'public' AND table_name = 'installation_work_items' 
                       AND column_name = 'title') THEN
            ALTER TABLE public.installation_work_items 
            ADD COLUMN title VARCHAR(255) NOT NULL DEFAULT 'Work Item';
            RAISE NOTICE 'Added title column to installation_work_items';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_schema = 'public' AND table_name = 'installation_work_items' 
                       AND column_name = 'status') THEN
            ALTER TABLE public.installation_work_items 
            ADD COLUMN status VARCHAR(50) DEFAULT 'not_started' 
            CHECK (status IN ('not_started', 'assigned', 'in_progress', 'verification_pending', 'completed', 'on_hold'));
            RAISE NOTICE 'Added status column to installation_work_items';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_schema = 'public' AND table_name = 'installation_work_items' 
                       AND column_name = 'team_member_ids') THEN
            ALTER TABLE public.installation_work_items 
            ADD COLUMN team_member_ids JSONB DEFAULT '[]'::jsonb;
            RAISE NOTICE 'Added team_member_ids column to installation_work_items';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_schema = 'public' AND table_name = 'installation_work_items' 
                       AND column_name = 'required_materials') THEN
            ALTER TABLE public.installation_work_items 
            ADD COLUMN required_materials JSONB DEFAULT '{}'::jsonb;
            RAISE NOTICE 'Added required_materials column to installation_work_items';
        END IF;
    END IF;
    
    -- Create indexes if they don't exist
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_installation_projects_customer_name 
            ON public.installation_projects(customer_name);
        CREATE INDEX IF NOT EXISTS idx_installation_projects_location 
            ON public.installation_projects(site_latitude, site_longitude);
        CREATE INDEX IF NOT EXISTS idx_installation_work_items_project_id 
            ON public.installation_work_items(project_id);
        CREATE INDEX IF NOT EXISTS idx_installation_work_items_work_type 
            ON public.installation_work_items(work_type);
        CREATE INDEX IF NOT EXISTS idx_installation_work_items_status 
            ON public.installation_work_items(status);
        RAISE NOTICE 'Created/verified indexes';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Some indexes may already exist';
    END;
    
END $$;

-- Show final table structures
SELECT 'INSTALLATION_PROJECTS TABLE STRUCTURE:' as info;
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'installation_projects'
ORDER BY ordinal_position;

SELECT 'INSTALLATION_WORK_ITEMS TABLE STRUCTURE:' as info;
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'installation_work_items'
ORDER BY ordinal_position;
