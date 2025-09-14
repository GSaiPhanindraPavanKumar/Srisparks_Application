-- Force add columns to installation_work_sessions table (more explicit approach)

-- Check if table exists first
SELECT EXISTS (
   SELECT FROM information_schema.tables 
   WHERE table_name = 'installation_work_sessions'
);

-- Add location_verified column (drop first if exists, then add)
DO $$ 
BEGIN
    BEGIN
        ALTER TABLE installation_work_sessions ADD COLUMN location_verified BOOLEAN DEFAULT false;
        RAISE NOTICE 'Column location_verified added successfully';
    EXCEPTION
        WHEN duplicate_column THEN 
            RAISE NOTICE 'Column location_verified already exists';
    END;
END $$;

-- Add distance_from_customer column (drop first if exists, then add)
DO $$ 
BEGIN
    BEGIN
        ALTER TABLE installation_work_sessions ADD COLUMN distance_from_customer NUMERIC(10,2);
        RAISE NOTICE 'Column distance_from_customer added successfully';
    EXCEPTION
        WHEN duplicate_column THEN 
            RAISE NOTICE 'Column distance_from_customer already exists';
    END;
END $$;

-- Verify the columns were added
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'installation_work_sessions' 
AND column_name IN ('location_verified', 'distance_from_customer');