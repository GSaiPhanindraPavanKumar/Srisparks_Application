-- Emergency Checkout Script
-- Use this if you need to check out the current user's active attendance

-- Check out today's attendance for the current user
UPDATE attendance 
SET 
    check_out_time = NOW(),
    check_out_latitude = COALESCE(check_in_latitude, 0),  -- Use check-in location as fallback
    check_out_longitude = COALESCE(check_in_longitude, 0),
    status = 'checked_out',
    notes = COALESCE(notes || ' | ', '') || 'Manual checkout via SQL',
    updated_at = NOW()
WHERE user_id = auth.uid()
AND attendance_date = CURRENT_DATE
AND status = 'checked_in'
RETURNING 
    id,
    attendance_date,
    check_in_time,
    check_out_time,
    status;

-- Verify checkout
SELECT 
    'Checkout completed' as message,
    attendance_date,
    check_in_time,
    check_out_time,
    status
FROM attendance 
WHERE user_id = auth.uid()
AND attendance_date = CURRENT_DATE;
