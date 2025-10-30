-- Query to check current attendance status and trigger
-- Run this in Supabase SQL Editor to diagnose the issue

-- 1. Check if the new trigger exists
SELECT 
    tgname as trigger_name,
    tgtype,
    tgenabled
FROM pg_trigger 
WHERE tgname IN ('trigger_allow_checkin_despite_previous', 'trigger_auto_checkout_previous')
ORDER BY tgname;

-- 2. Check current user's attendance records
SELECT 
    id,
    user_id,
    attendance_date,
    check_in_time,
    check_out_time,
    status,
    notes,
    created_at
FROM attendance 
WHERE user_id = auth.uid()
ORDER BY attendance_date DESC, check_in_time DESC
LIMIT 10;

-- 3. Check for today's attendance specifically
SELECT 
    id,
    attendance_date,
    check_in_time,
    check_out_time,
    status,
    'Today record' as note
FROM attendance 
WHERE user_id = auth.uid()
AND attendance_date = CURRENT_DATE;

-- 4. Check for unchecked-out attendance (all dates)
SELECT 
    id,
    attendance_date,
    check_in_time,
    status,
    CASE 
        WHEN attendance_date = CURRENT_DATE THEN 'Today (blocking check-in)'
        WHEN attendance_date < CURRENT_DATE THEN 'Previous day (should be ignored by trigger)'
        ELSE 'Future date'
    END as issue_type
FROM attendance 
WHERE user_id = auth.uid()
AND status = 'checked_in'
ORDER BY attendance_date DESC;

-- 5. To fix: Check out today's record if it exists
-- Uncomment and run this if you want to check out:
/*
UPDATE attendance 
SET 
    check_out_time = NOW(),
    status = 'checked_out',
    updated_at = NOW()
WHERE user_id = auth.uid()
AND attendance_date = CURRENT_DATE
AND status = 'checked_in';
*/
