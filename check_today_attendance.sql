-- Check current attendance status to see what's blocking check-in

-- 1. Show TODAY's attendance for current user
SELECT 
    id,
    attendance_date,
    check_in_time,
    check_out_time,
    status,
    notes,
    'This is blocking your check-in' as reason
FROM attendance 
WHERE user_id = auth.uid()
AND attendance_date = CURRENT_DATE;

-- 2. If you want to CHECK OUT today's record so you can check in again:
-- Uncomment and run this:
/*
UPDATE attendance 
SET 
    check_out_time = NOW(),
    check_out_latitude = COALESCE(check_in_latitude, 0),
    check_out_longitude = COALESCE(check_in_longitude, 0),
    status = 'checked_out',
    updated_at = NOW()
WHERE user_id = auth.uid()
AND attendance_date = CURRENT_DATE
AND status = 'checked_in'
RETURNING id, attendance_date, check_in_time, check_out_time, status;
*/

-- 3. OR if you want to DELETE today's record (for testing only):
-- Uncomment and run this:
/*
DELETE FROM attendance 
WHERE user_id = auth.uid()
AND attendance_date = CURRENT_DATE
RETURNING id, attendance_date, 'Deleted' as action;
*/

-- 4. Show all your recent attendance
SELECT 
    attendance_date,
    status,
    check_in_time,
    check_out_time,
    CASE 
        WHEN attendance_date = CURRENT_DATE THEN '⚠️ TODAY'
        WHEN attendance_date < CURRENT_DATE THEN 'Previous day'
        ELSE 'Future'
    END as day_type
FROM attendance 
WHERE user_id = auth.uid()
ORDER BY attendance_date DESC
LIMIT 10;
