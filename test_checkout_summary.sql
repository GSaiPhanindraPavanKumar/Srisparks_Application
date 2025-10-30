-- Test script to verify checkout summary feature
-- Run this to check current attendance status and notes field

-- 1. Check today's attendance for the lead user
SELECT 
    id,
    user_id,
    attendance_date,
    check_in_time,
    check_out_time,
    notes,
    CASE 
        WHEN check_out_time IS NULL THEN 'CHECKED IN (needs checkout)'
        ELSE 'CHECKED OUT'
    END as status
FROM attendance
WHERE user_id = '6738b9a4-6cf9-48e2-b294-fa34eae5c328' -- lead@srisparks.in
  AND attendance_date = CURRENT_DATE
ORDER BY check_in_time DESC;

-- 2. Check all attendance records for today (all users)
SELECT 
    a.id,
    u.email,
    a.attendance_date,
    a.check_in_time,
    a.check_out_time,
    SUBSTRING(a.notes, 1, 50) as notes_preview,
    CASE 
        WHEN a.check_out_time IS NULL THEN 'ACTIVE'
        ELSE 'COMPLETED'
    END as status
FROM attendance a
JOIN users u ON a.user_id = u.id
WHERE a.attendance_date = CURRENT_DATE
ORDER BY a.check_in_time DESC;

-- 3. Check recent checkouts with notes (last 10)
SELECT 
    u.email,
    a.attendance_date,
    TO_CHAR(a.check_out_time, 'HH24:MI') as checkout_time,
    a.notes,
    LENGTH(a.notes) as note_length
FROM attendance a
JOIN users u ON a.user_id = u.id
WHERE a.check_out_time IS NOT NULL
  AND a.notes IS NOT NULL
ORDER BY a.check_out_time DESC
LIMIT 10;
