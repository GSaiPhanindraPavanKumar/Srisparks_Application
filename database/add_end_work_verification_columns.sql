-- Add end work location verification columns to installation_work_sessions table

-- Add end_location_verified column (boolean) - for end work verification
ALTER TABLE installation_work_sessions 
ADD COLUMN IF NOT EXISTS end_location_verified BOOLEAN DEFAULT false;

-- Add end_distance_from_customer column (numeric) - for end work distance
ALTER TABLE installation_work_sessions 
ADD COLUMN IF NOT EXISTS end_distance_from_customer NUMERIC(10,2);

-- Add comments for clarity
COMMENT ON COLUMN installation_work_sessions.end_location_verified IS 'Whether the employee end location was verified within required radius';
COMMENT ON COLUMN installation_work_sessions.end_distance_from_customer IS 'Distance in meters from employee end location to customer location';

-- Update existing records to have default values for end work verification
UPDATE installation_work_sessions 
SET end_location_verified = false, 
    end_distance_from_customer = null 
WHERE end_location_verified IS NULL;

-- Check the updated table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'installation_work_sessions' 
AND column_name IN ('location_verified', 'distance_from_customer', 'end_location_verified', 'end_distance_from_customer')
ORDER BY column_name;