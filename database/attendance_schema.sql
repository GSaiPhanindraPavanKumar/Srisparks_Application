-- Create attendance table for tracking employee check-ins and check-outs
CREATE TABLE IF NOT EXISTS attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    office_id UUID REFERENCES offices(id) ON DELETE SET NULL,
    check_in_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    check_out_time TIMESTAMPTZ,
    check_in_latitude DECIMAL(10, 8),
    check_in_longitude DECIMAL(11, 8),
    check_out_latitude DECIMAL(10, 8),
    check_out_longitude DECIMAL(11, 8),
    attendance_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'checked_in' CHECK (status IN ('checked_in', 'checked_out')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_attendance_user_id ON attendance(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_office_id ON attendance(office_id);
CREATE INDEX IF NOT EXISTS idx_attendance_check_in_time ON attendance(check_in_time);
CREATE INDEX IF NOT EXISTS idx_attendance_status ON attendance(status);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(attendance_date);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_attendance_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_attendance_updated_at ON attendance;
CREATE TRIGGER update_attendance_updated_at
    BEFORE UPDATE ON attendance
    FOR EACH ROW
    EXECUTE FUNCTION update_attendance_updated_at();

-- Enable Row Level Security
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Users can only see their own attendance records
CREATE POLICY "Users can view own attendance" ON attendance
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own attendance records
CREATE POLICY "Users can insert own attendance" ON attendance
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own attendance records
CREATE POLICY "Users can update own attendance" ON attendance
    FOR UPDATE USING (auth.uid() = user_id);

-- Directors can see all attendance records in their office
CREATE POLICY "Directors can view office attendance" ON attendance
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'director'
            AND users.office_id = attendance.office_id
        )
    );

-- Managers can see attendance records of their office
CREATE POLICY "Managers can view office attendance" ON attendance
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('manager', 'director')
            AND users.office_id = attendance.office_id
        )
    );

-- Function to update status when checking out
CREATE OR REPLACE FUNCTION calculate_attendance_hours()
RETURNS TRIGGER AS $$
BEGIN
    -- If check_out_time is being set, update status to checked_out
    IF NEW.check_out_time IS NOT NULL THEN
        NEW.status = 'checked_out';
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically calculate hours
DROP TRIGGER IF EXISTS calculate_attendance_hours ON attendance;
CREATE TRIGGER calculate_attendance_hours
    BEFORE INSERT OR UPDATE ON attendance
    FOR EACH ROW
    EXECUTE FUNCTION calculate_attendance_hours();

-- Function to prevent multiple active check-ins for the same user
CREATE OR REPLACE FUNCTION prevent_multiple_checkins()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if user already has an active check-in (not checked out)
    IF NEW.status = 'checked_in' AND EXISTS (
        SELECT 1 FROM attendance 
        WHERE user_id = NEW.user_id 
        AND status = 'checked_in' 
        AND id != COALESCE(NEW.id, gen_random_uuid())
    ) THEN
        RAISE EXCEPTION 'User already has an active check-in. Please check out first.';
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to prevent multiple check-ins
DROP TRIGGER IF EXISTS prevent_multiple_checkins ON attendance;
CREATE TRIGGER prevent_multiple_checkins
    BEFORE INSERT OR UPDATE ON attendance
    FOR EACH ROW
    EXECUTE FUNCTION prevent_multiple_checkins();

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON attendance TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
