-- Attendance System Updates Migration
-- Date: October 30, 2025
-- Purpose: Add check-in updates field and fix columns for latitude/longitude

-- 1. Ensure latitude/longitude columns exist with correct names
-- (The schema has them but let's make sure they're there)
DO $$ 
BEGIN
    -- Add check_in_latitude if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'attendance' AND column_name = 'check_in_latitude'
    ) THEN
        ALTER TABLE attendance ADD COLUMN check_in_latitude DOUBLE PRECISION;
    END IF;

    -- Add check_in_longitude if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'attendance' AND column_name = 'check_in_longitude'
    ) THEN
        ALTER TABLE attendance ADD COLUMN check_in_longitude DOUBLE PRECISION;
    END IF;

    -- Add check_out_latitude if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'attendance' AND column_name = 'check_out_latitude'
    ) THEN
        ALTER TABLE attendance ADD COLUMN check_out_latitude DOUBLE PRECISION;
    END IF;

    -- Add check_out_longitude if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'attendance' AND column_name = 'check_out_longitude'
    ) THEN
        ALTER TABLE attendance ADD COLUMN check_out_longitude DOUBLE PRECISION;
    END IF;

    -- Add attendance_date if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'attendance' AND column_name = 'attendance_date'
    ) THEN
        ALTER TABLE attendance ADD COLUMN attendance_date DATE NOT NULL DEFAULT CURRENT_DATE;
    END IF;

    -- NOTE: check_in_update and check_out_update fields are NOT used anymore
    -- Updates are now handled through the attendance_updates table
    -- These columns are left here for backwards compatibility only
END $$;

-- 2. Create index on attendance_date and status for faster queries
CREATE INDEX IF NOT EXISTS idx_attendance_date_status ON attendance(attendance_date, status);
CREATE INDEX IF NOT EXISTS idx_attendance_user_date ON attendance(user_id, attendance_date);

-- 3. Create a function to allow check-in even if previous day wasn't checked out
-- This fixes the issue where users can't check in if they forgot to checkout previous day
-- Instead of auto-checkout, we simply allow the new check-in to proceed
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

-- 4. Create trigger to allow check-in despite previous unchecked-out days
-- First, safely drop old triggers if they exist
DO $$ 
BEGIN
    -- Drop old auto_checkout trigger if exists
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_auto_checkout_previous') THEN
        EXECUTE 'DROP TRIGGER trigger_auto_checkout_previous ON attendance';
    END IF;
    
    -- Drop OLD prevent_multiple_checkins trigger (conflicts with new logic)
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'prevent_multiple_checkins') THEN
        EXECUTE 'DROP TRIGGER prevent_multiple_checkins ON attendance';
        RAISE NOTICE 'Dropped old prevent_multiple_checkins trigger - it was blocking check-ins from previous days';
    END IF;
    
    -- Drop current trigger if exists (for re-running migration)
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_allow_checkin_despite_previous') THEN
        EXECUTE 'DROP TRIGGER trigger_allow_checkin_despite_previous ON attendance';
    END IF;
END $$;

-- Create the new trigger (replaces prevent_multiple_checkins)
CREATE TRIGGER trigger_allow_checkin_despite_previous
    BEFORE INSERT ON attendance
    FOR EACH ROW
    WHEN (NEW.status = 'checked_in')
    EXECUTE FUNCTION allow_checkin_despite_previous();

-- 5. Update the status field to use better values
-- Ensure status column can handle our status values
DO $$
BEGIN
    -- Update old 'present' status to 'checked_in' for consistency
    UPDATE attendance 
    SET status = 'checked_in' 
    WHERE status = 'present' AND check_out_time IS NULL;

    -- Update old 'present' status to 'checked_out' if checkout time exists
    UPDATE attendance 
    SET status = 'checked_out' 
    WHERE status = 'present' AND check_out_time IS NOT NULL;
END $$;

-- 6. Create a view for easy querying of attendance with location info
-- Drop existing view first if it has incompatible structure
DROP VIEW IF EXISTS attendance_with_location CASCADE;
CREATE VIEW attendance_with_location AS
SELECT 
    a.id,
    a.user_id,
    a.office_id,
    u.full_name as user_name,
    u.role as user_role,
    a.attendance_date,
    a.check_in_time,
    a.check_out_time,
    a.check_in_latitude,
    a.check_in_longitude,
    a.check_out_latitude,
    a.check_out_longitude,
    a.status,
    a.notes,
    CASE 
        WHEN a.check_out_time IS NOT NULL THEN
            EXTRACT(EPOCH FROM (a.check_out_time - a.check_in_time)) / 3600
        ELSE NULL
    END as hours_worked,
    a.created_at,
    a.updated_at
FROM attendance a
LEFT JOIN users u ON a.user_id = u.id;

-- 7. Grant permissions
GRANT SELECT, INSERT, UPDATE ON attendance TO authenticated;
GRANT SELECT ON attendance_with_location TO authenticated;

-- 8. Create attendance_updates table for tracking user updates throughout the day
CREATE TABLE IF NOT EXISTS attendance_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attendance_id UUID NOT NULL REFERENCES attendance(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    update_text TEXT NOT NULL,
    update_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for attendance_updates
CREATE INDEX IF NOT EXISTS idx_attendance_updates_attendance_id ON attendance_updates(attendance_id);
CREATE INDEX IF NOT EXISTS idx_attendance_updates_user_id ON attendance_updates(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_updates_update_time ON attendance_updates(update_time);

-- 9. Add helpful comments
COMMENT ON TABLE attendance IS 'Employee attendance tracking with check-in/check-out times and locations. Updates are tracked in separate attendance_updates table.';
COMMENT ON COLUMN attendance.check_in_latitude IS 'Latitude coordinate captured during check-in';
COMMENT ON COLUMN attendance.check_in_longitude IS 'Longitude coordinate captured during check-in';
COMMENT ON COLUMN attendance.check_out_latitude IS 'Latitude coordinate captured during check-out';
COMMENT ON COLUMN attendance.check_out_longitude IS 'Longitude coordinate captured during check-out';
COMMENT ON COLUMN attendance.attendance_date IS 'Date of attendance (without time component)';
COMMENT ON COLUMN attendance.notes IS 'General notes, may include auto-checkout messages';

COMMENT ON TABLE attendance_updates IS 'User updates/status reports throughout the workday with location tracking - accessed via "Add Status Update" button';
COMMENT ON COLUMN attendance_updates.update_text IS 'User provided update/status message';
COMMENT ON COLUMN attendance_updates.update_time IS 'Timestamp when update was submitted';
COMMENT ON COLUMN attendance_updates.latitude IS 'Latitude coordinate when update was submitted';
COMMENT ON COLUMN attendance_updates.longitude IS 'Longitude coordinate when update was submitted';

-- 10. Create a view for attendance with all updates
-- Drop existing view first if it has incompatible structure
DROP VIEW IF EXISTS attendance_with_updates CASCADE;
CREATE VIEW attendance_with_updates AS
SELECT 
    a.id as attendance_id,
    a.user_id,
    u.full_name as user_name,
    u.role as user_role,
    a.attendance_date,
    a.check_in_time,
    a.check_out_time,
    a.check_in_latitude,
    a.check_in_longitude,
    a.check_out_latitude,
    a.check_out_longitude,
    a.status,
    a.notes,
    CASE 
        WHEN a.check_out_time IS NOT NULL THEN
            EXTRACT(EPOCH FROM (a.check_out_time - a.check_in_time)) / 3600
        ELSE NULL
    END as hours_worked,
    -- Aggregate all updates into JSON array
    COALESCE(
        (
            SELECT json_agg(
                json_build_object(
                    'id', au.id,
                    'update_text', au.update_text,
                    'update_time', au.update_time,
                    'latitude', au.latitude,
                    'longitude', au.longitude
                ) ORDER BY au.update_time
            )
            FROM attendance_updates au
            WHERE au.attendance_id = a.id
        ),
        '[]'::json
    ) as updates,
    a.created_at,
    a.updated_at
FROM attendance a
LEFT JOIN users u ON a.user_id = u.id;

-- 11. Grant permissions
GRANT SELECT, INSERT, UPDATE ON attendance TO authenticated;
GRANT SELECT, INSERT ON attendance_updates TO authenticated;
GRANT SELECT ON attendance_with_updates TO authenticated;

-- 12. Create function to validate update belongs to current user
CREATE OR REPLACE FUNCTION check_attendance_update_owner()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure the user_id in the update matches the authenticated user
    IF NEW.user_id != auth.uid()::uuid THEN
        RAISE EXCEPTION 'You can only add updates to your own attendance';
    END IF;
    
    -- Ensure the attendance record belongs to the user
    IF NOT EXISTS (
        SELECT 1 FROM attendance 
        WHERE id = NEW.attendance_id 
        AND user_id = NEW.user_id
    ) THEN
        RAISE EXCEPTION 'Attendance record not found or does not belong to you';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13. Create trigger for attendance updates validation
DO $$ 
BEGIN
    -- Drop existing trigger if it exists
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_check_attendance_update_owner') THEN
        EXECUTE 'DROP TRIGGER trigger_check_attendance_update_owner ON attendance_updates';
    END IF;
END $$;

CREATE TRIGGER trigger_check_attendance_update_owner
    BEFORE INSERT ON attendance_updates
    FOR EACH ROW
    EXECUTE FUNCTION check_attendance_update_owner();

-- Migration completed successfully
SELECT 'Attendance system updates migration completed successfully!' as result;
