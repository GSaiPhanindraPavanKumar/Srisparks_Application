-- Check if the columns exist in the installation_work_sessions table
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'installation_work_sessions' 
AND column_name IN ('location_verified', 'distance_from_customer')
ORDER BY column_name;