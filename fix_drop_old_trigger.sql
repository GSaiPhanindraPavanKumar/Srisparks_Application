-- QUICK FIX: Drop the problematic prevent_multiple_checkins trigger
-- This trigger is blocking check-ins even from previous days
-- Run this FIRST, then you can check in

-- Drop the old trigger
DROP TRIGGER IF EXISTS prevent_multiple_checkins ON attendance;

-- Verify it's gone
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'prevent_multiple_checkins')
        THEN 'ERROR: Trigger still exists!'
        ELSE 'SUCCESS: Old trigger removed. You can now check in!'
    END as status;

-- Show current triggers on attendance table
SELECT 
    tgname as trigger_name,
    CASE 
        WHEN tgname = 'trigger_allow_checkin_despite_previous' THEN 'Good - New flexible trigger'
        WHEN tgname = 'prevent_multiple_checkins' THEN 'Bad - Old blocking trigger'
        ELSE 'Other trigger'
    END as description
FROM pg_trigger 
WHERE tgrelid = 'attendance'::regclass
ORDER BY tgname;
