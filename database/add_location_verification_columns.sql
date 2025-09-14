-- Add location verification columns to installation_work_sessions table

-- Add location_verified column (boolean)
ALTER TABLE installation_work_sessions 
ADD COLUMN IF NOT EXISTS location_verified BOOLEAN DEFAULT false;

-- Add distance_from_customer column (numeric for storing distance in meters)
ALTER TABLE installation_work_sessions 
ADD COLUMN IF NOT EXISTS distance_from_customer NUMERIC(10,2);

-- Add comment for clarity
COMMENT ON COLUMN installation_work_sessions.location_verified IS 'Whether the employee location was verified within required radius';
COMMENT ON COLUMN installation_work_sessions.distance_from_customer IS 'Distance in meters from employee location to customer location';

-- Update existing records to have default values
UPDATE installation_work_sessions 
SET location_verified = false, 
    distance_from_customer = null 
WHERE location_verified IS NULL;