-- COMPLETE FIX FOR CHECK-IN ISSUE
-- This script will:
-- 1. Drop the old prevent_multiple_checkins trigger
-- 2. Ensure the new trigger is installed
-- 3. Allow you to check in today

-- Step 1: Drop the problematic old trigger
DROP TRIGGER IF EXISTS prevent_multiple_checkins ON attendance;

-- Step 2: Drop and recreate the new trigger to ensure it's working
DROP TRIGGER IF EXISTS trigger_allow_checkin_despite_previous ON attendance;

-- Step 3: Ensure the function exists
CREATE OR REPLACE FUNCTION allow_checkin_despite_previous()
RETURNS TRIGGER AS $$
DECLARE
    v_existing_today RECORD;
BEGIN
    -- Only check for duplicate check-ins on the SAME day
    -- Ignore any unchecked-out attendance from previous days
    SELECT * INTO v_existing_today
    FROM attendance
    WHERE user_id = NEW.user_id
      AND status = 'checked_in'
      AND attendance_date = NEW.attendance_date
      AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid);
    
    -- If user already checked in TODAY, prevent duplicate
    IF v_existing_today.id IS NOT NULL THEN
        RAISE EXCEPTION 'You are already checked in for today. Please check out first.';
    END IF;
    
    -- Otherwise, allow the check-in (even if previous days are unchecked-out)
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Create the new trigger
CREATE TRIGGER trigger_allow_checkin_despite_previous
    BEFORE INSERT ON attendance
    FOR EACH ROW
    WHEN (NEW.status = 'checked_in')
    EXECUTE FUNCTION allow_checkin_despite_previous();

-- Step 5: Verify the fix
SELECT 
    '✅ Fix completed! Old trigger removed, new trigger installed.' as status,
    'You can now check in despite having unchecked-out attendance from previous days.' as message;

-- Step 6: Show all current triggers
SELECT 
    tgname as trigger_name,
    tgenabled as enabled,
    CASE 
        WHEN tgname = 'trigger_allow_checkin_despite_previous' THEN '✅ NEW - Allows check-in (ignores previous days)'
        WHEN tgname = 'prevent_multiple_checkins' THEN '❌ OLD - Should be removed'
        WHEN tgname = 'calculate_attendance_hours' THEN 'ℹ️ Utility - Calculates hours'
        WHEN tgname = 'update_attendance_updated_at' THEN 'ℹ️ Utility - Updates timestamp'
        ELSE 'ℹ️ Other'
    END as description
FROM pg_trigger 
WHERE tgrelid = 'attendance'::regclass
ORDER BY tgname;

-- Step 7: Show your current attendance records
SELECT 
    attendance_date,
    status,
    check_in_time,
    check_out_time,
    CASE 
        WHEN attendance_date = CURRENT_DATE AND status = 'checked_in' THEN '⚠️ Already checked in TODAY - will block new check-in'
        WHEN attendance_date < CURRENT_DATE AND status = 'checked_in' THEN '✅ Previous day unchecked - will be IGNORED by new trigger'
        WHEN status = 'checked_out' THEN '✅ Checked out - no issue'
        ELSE 'ℹ️ Other'
    END as impact
FROM attendance 
WHERE user_id = auth.uid()
ORDER BY attendance_date DESC
LIMIT 5;
