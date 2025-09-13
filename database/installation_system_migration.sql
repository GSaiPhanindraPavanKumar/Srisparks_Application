-- Installation System Database Migration
-- This script creates the necessary tables for the installation assignment and management system

-- 1. Create installation_projects table
CREATE TABLE IF NOT EXISTS installation_projects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'created',
    assigned_by_id UUID NOT NULL REFERENCES users(id),
    assigned_date TIMESTAMPTZ DEFAULT NOW(),
    started_date TIMESTAMPTZ,
    completed_date TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT installation_projects_status_check 
    CHECK (status IN ('created', 'assigned', 'in_progress', 'completed', 'verified', 'approved'))
);

-- 2. Create installation_work_items table
CREATE TABLE IF NOT EXISTS installation_work_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES installation_projects(id) ON DELETE CASCADE,
    work_type VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'notStarted',
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    estimated_hours INTEGER,
    actual_hours INTEGER,
    progress_percentage INTEGER DEFAULT 0,
    completion_photos TEXT[], -- Array of photo URLs
    completion_notes TEXT,
    verification_status VARCHAR(50) DEFAULT 'pending',
    verified_by_id UUID REFERENCES users(id),
    verified_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT installation_work_items_status_check 
    CHECK (status IN ('notStarted', 'inProgress', 'awaitingCompletion', 'completed', 'verified', 'acknowledged', 'approved')),
    
    CONSTRAINT installation_work_items_work_type_check 
    CHECK (work_type IN ('structureWork', 'panels', 'inverterWiring', 'earthing', 'lightningArrestor')),
    
    CONSTRAINT installation_work_items_verification_status_check 
    CHECK (verification_status IN ('pending', 'verified', 'rejected')),
    
    CONSTRAINT installation_work_items_progress_check 
    CHECK (progress_percentage >= 0 AND progress_percentage <= 100)
);

-- 3. Create installation_employee_assignments table (many-to-many relationship)
CREATE TABLE IF NOT EXISTS installation_employee_assignments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    work_item_id UUID NOT NULL REFERENCES installation_work_items(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assigned_by_id UUID NOT NULL REFERENCES users(id),
    assigned_date TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Unique constraint to prevent duplicate assignments
    UNIQUE(work_item_id, employee_id)
);

-- 4. Create installation_work_sessions table (for GPS tracking and time logging)
CREATE TABLE IF NOT EXISTS installation_work_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    work_item_id UUID NOT NULL REFERENCES installation_work_items(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    start_latitude DECIMAL(10, 8),
    start_longitude DECIMAL(11, 8),
    end_latitude DECIMAL(10, 8),
    end_longitude DECIMAL(11, 8),
    distance_from_site DECIMAL(10, 2), -- Distance in meters
    session_notes TEXT,
    photos TEXT[], -- Array of photo URLs taken during session
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Create installation_location_logs table (for periodic GPS verification)
CREATE TABLE IF NOT EXISTS installation_location_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    work_session_id UUID NOT NULL REFERENCES installation_work_sessions(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    check_time TIMESTAMPTZ DEFAULT NOW(),
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    distance_from_site DECIMAL(10, 2), -- Distance in meters
    is_within_radius BOOLEAN DEFAULT FALSE,
    accuracy DECIMAL(10, 2), -- GPS accuracy in meters
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_installation_projects_customer_id ON installation_projects(customer_id);
CREATE INDEX IF NOT EXISTS idx_installation_projects_status ON installation_projects(status);
CREATE INDEX IF NOT EXISTS idx_installation_projects_assigned_by ON installation_projects(assigned_by_id);

CREATE INDEX IF NOT EXISTS idx_installation_work_items_project_id ON installation_work_items(project_id);
CREATE INDEX IF NOT EXISTS idx_installation_work_items_status ON installation_work_items(status);
CREATE INDEX IF NOT EXISTS idx_installation_work_items_work_type ON installation_work_items(work_type);

CREATE INDEX IF NOT EXISTS idx_installation_employee_assignments_work_item ON installation_employee_assignments(work_item_id);
CREATE INDEX IF NOT EXISTS idx_installation_employee_assignments_employee ON installation_employee_assignments(employee_id);

CREATE INDEX IF NOT EXISTS idx_installation_work_sessions_work_item ON installation_work_sessions(work_item_id);
CREATE INDEX IF NOT EXISTS idx_installation_work_sessions_employee ON installation_work_sessions(employee_id);
CREATE INDEX IF NOT EXISTS idx_installation_work_sessions_start_time ON installation_work_sessions(start_time);

CREATE INDEX IF NOT EXISTS idx_installation_location_logs_session ON installation_location_logs(work_session_id);
CREATE INDEX IF NOT EXISTS idx_installation_location_logs_employee ON installation_location_logs(employee_id);
CREATE INDEX IF NOT EXISTS idx_installation_location_logs_check_time ON installation_location_logs(check_time);

-- 7. Create updated_at trigger for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_installation_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply the trigger to relevant tables
DROP TRIGGER IF EXISTS update_installation_projects_updated_at ON installation_projects;
CREATE TRIGGER update_installation_projects_updated_at
    BEFORE UPDATE ON installation_projects
    FOR EACH ROW
    EXECUTE FUNCTION update_installation_updated_at_column();

DROP TRIGGER IF EXISTS update_installation_work_items_updated_at ON installation_work_items;
CREATE TRIGGER update_installation_work_items_updated_at
    BEFORE UPDATE ON installation_work_items
    FOR EACH ROW
    EXECUTE FUNCTION update_installation_updated_at_column();

DROP TRIGGER IF EXISTS update_installation_work_sessions_updated_at ON installation_work_sessions;
CREATE TRIGGER update_installation_work_sessions_updated_at
    BEFORE UPDATE ON installation_work_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_installation_updated_at_column();

-- 8. Create RLS (Row Level Security) policies for data access control
ALTER TABLE installation_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE installation_work_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE installation_employee_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE installation_work_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE installation_location_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for installation_projects
CREATE POLICY "Directors can access all installation projects" ON installation_projects
    FOR ALL USING (auth.jwt() ->> 'role' = 'director');

CREATE POLICY "Managers can access projects in their office" ON installation_projects
    FOR ALL USING (
        auth.jwt() ->> 'role' = 'manager' AND
        customer_id IN (
            SELECT id FROM customers 
            WHERE office_id = (auth.jwt() ->> 'office_id')::uuid
        )
    );

CREATE POLICY "Employees can access projects they are assigned to" ON installation_projects
    FOR SELECT USING (
        auth.jwt() ->> 'role' = 'employee' AND
        id IN (
            SELECT DISTINCT iwi.project_id FROM installation_work_items iwi
            JOIN installation_employee_assignments iea ON iwi.id = iea.work_item_id
            WHERE iea.employee_id = (auth.jwt() ->> 'sub')::uuid
        )
    );

-- RLS Policies for installation_work_items
CREATE POLICY "Directors can access all work items" ON installation_work_items
    FOR ALL USING (auth.jwt() ->> 'role' = 'director');

CREATE POLICY "Managers can access work items in their office" ON installation_work_items
    FOR ALL USING (
        auth.jwt() ->> 'role' = 'manager' AND
        project_id IN (
            SELECT ip.id FROM installation_projects ip
            JOIN customers c ON ip.customer_id = c.id
            WHERE c.office_id = (auth.jwt() ->> 'office_id')::uuid
        )
    );

CREATE POLICY "Employees can access work items assigned to them" ON installation_work_items
    FOR ALL USING (
        auth.jwt() ->> 'role' = 'employee' AND
        id IN (
            SELECT work_item_id FROM installation_employee_assignments
            WHERE employee_id = (auth.jwt() ->> 'sub')::uuid
        )
    );

-- RLS Policies for installation_employee_assignments
CREATE POLICY "Directors and managers can manage employee assignments" ON installation_employee_assignments
    FOR ALL USING (auth.jwt() ->> 'role' IN ('director', 'manager'));

CREATE POLICY "Employees can view their assignments" ON installation_employee_assignments
    FOR SELECT USING (employee_id = (auth.jwt() ->> 'sub')::uuid);

-- RLS Policies for installation_work_sessions
CREATE POLICY "Directors can access all work sessions" ON installation_work_sessions
    FOR ALL USING (auth.jwt() ->> 'role' = 'director');

CREATE POLICY "Managers can access sessions in their office" ON installation_work_sessions
    FOR ALL USING (
        auth.jwt() ->> 'role' = 'manager' AND
        work_item_id IN (
            SELECT iwi.id FROM installation_work_items iwi
            JOIN installation_projects ip ON iwi.project_id = ip.id
            JOIN customers c ON ip.customer_id = c.id
            WHERE c.office_id = (auth.jwt() ->> 'office_id')::uuid
        )
    );

CREATE POLICY "Employees can manage their own work sessions" ON installation_work_sessions
    FOR ALL USING (employee_id = (auth.jwt() ->> 'sub')::uuid);

-- RLS Policies for installation_location_logs
CREATE POLICY "Directors can access all location logs" ON installation_location_logs
    FOR ALL USING (auth.jwt() ->> 'role' = 'director');

CREATE POLICY "Managers can access location logs in their office" ON installation_location_logs
    FOR ALL USING (
        auth.jwt() ->> 'role' = 'manager' AND
        work_session_id IN (
            SELECT iws.id FROM installation_work_sessions iws
            JOIN installation_work_items iwi ON iws.work_item_id = iwi.id
            JOIN installation_projects ip ON iwi.project_id = ip.id
            JOIN customers c ON ip.customer_id = c.id
            WHERE c.office_id = (auth.jwt() ->> 'office_id')::uuid
        )
    );

CREATE POLICY "Employees can access their own location logs" ON installation_location_logs
    FOR ALL USING (employee_id = (auth.jwt() ->> 'sub')::uuid);

-- 9. Create helpful views for common queries
CREATE OR REPLACE VIEW installation_project_overview AS
SELECT 
    ip.id as project_id,
    ip.customer_id,
    c.name as customer_name,
    c.address as customer_address,
    c.latitude as site_latitude,
    c.longitude as site_longitude,
    c.office_id,
    o.name as office_name,
    ip.status as project_status,
    u.full_name as assigned_by_name,
    ip.assigned_date,
    ip.started_date,
    ip.completed_date,
    ip.notes,
    ip.created_at,
    ip.updated_at,
    COUNT(iwi.id) as total_work_items,
    COUNT(CASE WHEN iwi.status = 'completed' THEN 1 END) as completed_work_items,
    COUNT(CASE WHEN iwi.status = 'verified' THEN 1 END) as verified_work_items,
    ROUND(
        (COUNT(CASE WHEN iwi.status IN ('completed', 'verified', 'approved') THEN 1 END) * 100.0) / 
        NULLIF(COUNT(iwi.id), 0), 2
    ) as completion_percentage
FROM installation_projects ip
JOIN customers c ON ip.customer_id = c.id
LEFT JOIN offices o ON c.office_id = o.id
LEFT JOIN users u ON ip.assigned_by_id = u.id
LEFT JOIN installation_work_items iwi ON ip.id = iwi.project_id
GROUP BY ip.id, ip.customer_id, c.name, c.address, c.latitude, c.longitude, 
         c.office_id, o.name, ip.status, u.full_name, ip.assigned_date, 
         ip.started_date, ip.completed_date, ip.notes, ip.created_at, ip.updated_at;

CREATE OR REPLACE VIEW employee_work_assignments AS
SELECT 
    u.id as employee_id,
    u.full_name as employee_name,
    u.office_id,
    o.name as office_name,
    iwi.id as work_item_id,
    iwi.work_type,
    iwi.status as work_status,
    iwi.progress_percentage,
    ip.id as project_id,
    c.name as customer_name,
    c.address as customer_address,
    c.phone_number as customer_phone,
    iea.assigned_date,
    iws.start_time as current_session_start,
    CASE WHEN iws.end_time IS NULL AND iws.start_time IS NOT NULL THEN TRUE ELSE FALSE END as is_currently_working
FROM users u
JOIN installation_employee_assignments iea ON u.id = iea.employee_id
JOIN installation_work_items iwi ON iea.work_item_id = iwi.id
JOIN installation_projects ip ON iwi.project_id = ip.id
JOIN customers c ON ip.customer_id = c.id
LEFT JOIN offices o ON u.office_id = o.id
LEFT JOIN installation_work_sessions iws ON iwi.id = iws.work_item_id AND u.id = iws.employee_id AND iws.end_time IS NULL
WHERE iea.is_active = TRUE
ORDER BY u.full_name, iea.assigned_date DESC;

-- Additional view for detailed work item information
CREATE OR REPLACE VIEW installation_work_item_details AS
SELECT 
    iwi.id as id, -- Use 'id' instead of 'work_item_id' to match model
    iwi.work_type,
    iwi.status,
    iwi.progress_percentage,
    iwi.verification_status,
    iwi.start_time,
    iwi.end_time,
    iwi.estimated_hours,
    iwi.actual_hours,
    iwi.completion_notes as work_notes,
    iwi.completion_photos as work_photos,
    verified_user.full_name as verified_by,
    iwi.verified_date as verified_at,
    ip.id as project_id,
    c.id as customer_id,
    c.name as customer_name,
    c.address as customer_address,
    c.address as site_address, -- Add site_address field
    c.latitude as site_latitude,
    c.longitude as site_longitude,
    c.phone_number as customer_phone,
    o.name as office_name,
    assigned_user.full_name as assigned_by_name,
    ip.assigned_date,
    iwi.created_at,
    iwi.updated_at,
    -- Lead employee info (first assigned employee as lead for now)
    (ARRAY_AGG(emp.id) FILTER (WHERE emp.id IS NOT NULL))[1] as lead_employee_id,
    (ARRAY_AGG(emp.full_name) FILTER (WHERE emp.full_name IS NOT NULL))[1] as lead_employee_name,
    -- Employee assignments (aggregated)
    ARRAY_AGG(DISTINCT emp.id) FILTER (WHERE emp.id IS NOT NULL) as team_member_ids,
    ARRAY_AGG(DISTINCT emp.full_name) FILTER (WHERE emp.full_name IS NOT NULL) as team_member_names,
    ARRAY_AGG(DISTINCT emp.id) FILTER (WHERE emp.id IS NOT NULL) as assigned_employee_ids,
    ARRAY_AGG(DISTINCT emp.full_name) FILTER (WHERE emp.full_name IS NOT NULL) as assigned_employee_names
FROM installation_work_items iwi
JOIN installation_projects ip ON iwi.project_id = ip.id
JOIN customers c ON ip.customer_id = c.id
LEFT JOIN offices o ON c.office_id = o.id
LEFT JOIN users assigned_user ON ip.assigned_by_id = assigned_user.id
LEFT JOIN users verified_user ON iwi.verified_by_id = verified_user.id
LEFT JOIN installation_employee_assignments iea ON iwi.id = iea.work_item_id AND iea.is_active = TRUE
LEFT JOIN users emp ON iea.employee_id = emp.id
GROUP BY iwi.id, iwi.work_type, iwi.status, iwi.progress_percentage, iwi.verification_status,
         iwi.start_time, iwi.end_time, iwi.estimated_hours, iwi.actual_hours, iwi.completion_notes,
         iwi.completion_photos, verified_user.full_name, iwi.verified_date, ip.id, c.id, c.name, 
         c.address, c.latitude, c.longitude, c.phone_number, o.name, assigned_user.full_name, 
         ip.assigned_date, iwi.created_at, iwi.updated_at;

-- 10. Insert some sample work types (if needed)
-- This can be used to populate default work types if your application needs them

-- 11. Add scheduled_start_date column to installation_projects table
-- This column stores the planned/scheduled start date for the installation project
ALTER TABLE installation_projects 
ADD COLUMN IF NOT EXISTS scheduled_start_date TIMESTAMPTZ;

-- Add comment to the column for documentation
COMMENT ON COLUMN installation_projects.scheduled_start_date IS 'Planned/scheduled start date for the installation project - used for planning and coordination purposes';

-- Update the installation_project_overview view to include scheduled_start_date
DROP VIEW IF EXISTS installation_project_overview;
CREATE VIEW installation_project_overview AS
SELECT 
    ip.id as project_id,
    ip.customer_id,
    c.name as customer_name,
    c.address as customer_address,
    c.phone_number as customer_phone,
    c.latitude as site_latitude,
    c.longitude as site_longitude,
    o.name as office_name,
    ip.status as project_status,
    ip.assigned_by_id,
    assigned_user.full_name as assigned_by_name,
    ip.assigned_date,
    ip.scheduled_start_date,  -- Include the new scheduled start date
    ip.started_date,
    ip.completed_date,
    ip.notes as project_notes,
    COUNT(iwi.id) as total_work_items,
    COUNT(CASE WHEN iwi.status = 'completed' THEN 1 END) as completed_work_items,
    COUNT(CASE WHEN iwi.verification_status = 'verified' THEN 1 END) as verified_work_items,
    COALESCE(AVG(iwi.progress_percentage), 0) as overall_progress_percentage,
    ip.created_at,
    ip.updated_at
FROM installation_projects ip
JOIN customers c ON ip.customer_id = c.id
LEFT JOIN offices o ON c.office_id = o.id
LEFT JOIN users assigned_user ON ip.assigned_by_id = assigned_user.id
LEFT JOIN installation_work_items iwi ON ip.id = iwi.project_id
GROUP BY ip.id, c.id, c.name, c.address, c.phone_number, c.latitude, c.longitude,
         o.name, assigned_user.full_name, ip.assigned_date, ip.scheduled_start_date,
         ip.started_date, ip.completed_date, ip.notes, ip.created_at, ip.updated_at;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Installation System Database Migration Complete!';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Created Tables:';
    RAISE NOTICE '• installation_projects - Main installation projects (with scheduled_start_date)';
    RAISE NOTICE '• installation_work_items - Individual work tasks';
    RAISE NOTICE '• installation_employee_assignments - Employee assignments';
    RAISE NOTICE '• installation_work_sessions - Work time tracking';
    RAISE NOTICE '• installation_location_logs - GPS verification logs';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 RLS Policies Applied:';
    RAISE NOTICE '• Directors: Full access to all installation data';
    RAISE NOTICE '• Managers: Access to installations in their office';
    RAISE NOTICE '• Employees: Access to their assigned work only';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Views Created:';
    RAISE NOTICE '• installation_project_overview - Project progress summary (includes scheduled_start_date)';
    RAISE NOTICE '• employee_work_assignments - Employee work assignments overview';
    RAISE NOTICE '';
    RAISE NOTICE '🆕 New Features Added:';
    RAISE NOTICE '• scheduled_start_date column for project planning';
    RAISE NOTICE '• Updated views to include scheduled start dates';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Ready for Installation Assignment System with Scheduling!';
END $$;
