-- Setup Director Office Access
-- This script ensures directors have NULL office_id for "all offices" access

-- Update existing directors to have NULL office_id
UPDATE users 
SET office_id = NULL 
WHERE role = 'director';

-- Add constraint to ensure only directors can have NULL office_id
ALTER TABLE users 
ADD CONSTRAINT office_id_null_only_for_directors 
CHECK (
  (role = 'director' AND office_id IS NULL) OR 
  (role IN ('manager', 'employee') AND office_id IS NOT NULL)
);

-- Add comment explaining the office access pattern
COMMENT ON COLUMN users.office_id IS 'NULL for directors (all offices access), required for managers/employees (specific office access)';

-- Verification query to check current setup
SELECT 
    role,
    COUNT(*) as count,
    COUNT(office_id) as with_office_id,
    COUNT(*) - COUNT(office_id) as without_office_id
FROM users 
GROUP BY role
ORDER BY role;

-- Show all directors and their current office assignments (should all be NULL)
SELECT 
    id,
    email,
    full_name,
    office_id,
    status
FROM users 
WHERE role = 'director'
ORDER BY email;

-- Show sample of non-directors and their office assignments (should all have office_id)
SELECT 
    id,
    email,
    full_name,
    role,
    office_id,
    status
FROM users 
WHERE role IN ('manager', 'employee')
AND office_id IS NULL  -- These are problematic records
ORDER BY role, email;
