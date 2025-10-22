-- Fix Attendance Table Foreign Key Relationship
-- Run this in your Supabase SQL Editor to establish proper relationship

-- Step 1: Add foreign key constraint if it doesn't exist
DO $$
BEGIN
    -- Check if the foreign key constraint already exists
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE constraint_name = 'attendance_user_id_fkey'
        AND table_name = 'attendance'
    ) THEN
        -- Add the foreign key constraint
        ALTER TABLE attendance
        ADD CONSTRAINT attendance_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE;

        RAISE NOTICE 'Foreign key constraint added successfully';
    ELSE
        RAISE NOTICE 'Foreign key constraint already exists';
    END IF;
END $$;

-- Step 2: Add index on user_id for better performance
CREATE INDEX IF NOT EXISTS idx_attendance_user_id ON attendance(user_id);

-- Step 3: Add index on office_id for better filtering
CREATE INDEX IF NOT EXISTS idx_attendance_office_id ON attendance(office_id);

-- Step 4: Add composite index for common queries
CREATE INDEX IF NOT EXISTS idx_attendance_office_date 
ON attendance(office_id, attendance_date);

-- Step 5: Add index for check_in_time queries
CREATE INDEX IF NOT EXISTS idx_attendance_check_in_time 
ON attendance(check_in_time DESC);

-- Step 6: Verify the foreign key was created
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'attendance'
    AND kcu.column_name = 'user_id';

-- Step 7: Test the relationship with a sample query (optional)
-- This should work after the foreign key is set up
-- SELECT 
--     a.*,
--     u.full_name,
--     u.email,
--     u.role,
--     u.is_lead
-- FROM attendance a
-- INNER JOIN users u ON a.user_id = u.id
-- LIMIT 5;

COMMENT ON CONSTRAINT attendance_user_id_fkey ON attendance IS 
'Foreign key linking attendance records to users table';
