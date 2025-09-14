-- Check full table structure for installation_work_sessions
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'installation_work_sessions' 
ORDER BY ordinal_position;