-- Create installation_assignment_employees table for many-to-many relationship
-- This table supports the team-based installation workflow described in the documentation

CREATE TABLE IF NOT EXISTS installation_assignment_employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID NOT NULL REFERENCES installation_work_assignments(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_in_assignment TEXT DEFAULT 'member' CHECK (role_in_assignment IN ('lead', 'member', 'assistant')),
    assigned_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure unique employee per assignment
    UNIQUE(assignment_id, employee_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_installation_assignment_employees_assignment 
ON installation_assignment_employees(assignment_id);

CREATE INDEX IF NOT EXISTS idx_installation_assignment_employees_employee 
ON installation_assignment_employees(employee_id);

CREATE INDEX IF NOT EXISTS idx_installation_assignment_employees_role 
ON installation_assignment_employees(role_in_assignment);

-- Create installation_sub_tasks table for detailed task tracking
CREATE TABLE IF NOT EXISTS installation_sub_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID NOT NULL REFERENCES installation_work_assignments(id) ON DELETE CASCADE,
    sub_task_type TEXT NOT NULL CHECK (sub_task_type IN ('structure', 'panels', 'wiring_inverter', 'earthing', 'lightning_arrestor', 'data_collection')),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    started_by_employee_id UUID REFERENCES users(id),
    completed_by_employee_id UUID REFERENCES users(id),
    start_latitude DOUBLE PRECISION,
    start_longitude DOUBLE PRECISION,
    completion_latitude DOUBLE PRECISION,
    completion_longitude DOUBLE PRECISION,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure unique sub-task per assignment
    UNIQUE(assignment_id, sub_task_type)
);

-- Create indexes for sub-tasks
CREATE INDEX IF NOT EXISTS idx_installation_sub_tasks_assignment 
ON installation_sub_tasks(assignment_id);

CREATE INDEX IF NOT EXISTS idx_installation_sub_tasks_status 
ON installation_sub_tasks(status);

CREATE INDEX IF NOT EXISTS idx_installation_sub_tasks_type 
ON installation_sub_tasks(sub_task_type);

-- Create installation_task_photos table for photo evidence
CREATE TABLE IF NOT EXISTS installation_task_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_task_id UUID NOT NULL REFERENCES installation_sub_tasks(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    photo_type TEXT DEFAULT 'progress' CHECK (photo_type IN ('before', 'progress', 'completed', 'verification')),
    captured_by_employee_id UUID REFERENCES users(id),
    captured_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    file_size_bytes INTEGER,
    mime_type TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for photos
CREATE INDEX IF NOT EXISTS idx_installation_task_photos_sub_task 
ON installation_task_photos(sub_task_id);

CREATE INDEX IF NOT EXISTS idx_installation_task_photos_type 
ON installation_task_photos(photo_type);

-- Create installation_equipment_serials table for equipment tracking
CREATE TABLE IF NOT EXISTS installation_equipment_serials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_task_id UUID NOT NULL REFERENCES installation_sub_tasks(id) ON DELETE CASCADE,
    equipment_type TEXT NOT NULL CHECK (equipment_type IN ('panel', 'inverter', 'battery', 'meter', 'other')),
    serial_number TEXT NOT NULL,
    manufacturer TEXT,
    model TEXT,
    specifications JSONB DEFAULT '{}'::jsonb,
    recorded_by_employee_id UUID REFERENCES users(id),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for equipment serials
CREATE INDEX IF NOT EXISTS idx_installation_equipment_serials_sub_task 
ON installation_equipment_serials(sub_task_id);

CREATE INDEX IF NOT EXISTS idx_installation_equipment_serials_type 
ON installation_equipment_serials(equipment_type);

CREATE INDEX IF NOT EXISTS idx_installation_equipment_serials_serial 
ON installation_equipment_serials(serial_number);

-- Create installation_task_team_members table for team tracking per sub-task
CREATE TABLE IF NOT EXISTS installation_task_team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_task_id UUID NOT NULL REFERENCES installation_sub_tasks(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_in_task TEXT DEFAULT 'member' CHECK (role_in_task IN ('lead', 'member', 'assistant')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    left_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure unique employee per sub-task
    UNIQUE(sub_task_id, employee_id)
);

-- Create indexes for team members
CREATE INDEX IF NOT EXISTS idx_installation_task_team_members_sub_task 
ON installation_task_team_members(sub_task_id);

CREATE INDEX IF NOT EXISTS idx_installation_task_team_members_employee 
ON installation_task_team_members(employee_id);

-- Create views for easier querying as mentioned in documentation

-- Installation assignment details view
CREATE OR REPLACE VIEW installation_assignment_details AS
SELECT 
    iwa.*,
    c.name as customer_name_ref,
    c.address as customer_address_ref,
    c.latitude as customer_latitude_ref,
    c.longitude as customer_longitude_ref,
    c.office_id as customer_office_id,
    assigned_by.full_name as assigned_by_name_ref,
    assigned_by.role as assigned_by_role,
    verified_by.full_name as verified_by_name_ref,
    verified_by.role as verified_by_role,
    ARRAY_AGG(DISTINCT u.full_name) FILTER (WHERE u.id IS NOT NULL) as assigned_employee_names_computed,
    ARRAY_AGG(DISTINCT iae.employee_id) FILTER (WHERE iae.employee_id IS NOT NULL) as assigned_employee_ids_computed,
    COUNT(ist.id) as total_sub_tasks,
    COUNT(ist.id) FILTER (WHERE ist.status = 'completed') as completed_sub_tasks,
    CASE 
        WHEN COUNT(ist.id) > 0 THEN 
            ROUND((COUNT(ist.id) FILTER (WHERE ist.status = 'completed')::decimal / COUNT(ist.id)) * 100, 2)
        ELSE 0 
    END as completion_percentage
FROM installation_work_assignments iwa
LEFT JOIN customers c ON iwa.customer_id = c.id
LEFT JOIN users assigned_by ON iwa.assigned_by_id = assigned_by.id
LEFT JOIN users verified_by ON iwa.verified_by_id = verified_by.id
LEFT JOIN installation_assignment_employees iae ON iwa.id = iae.assignment_id
LEFT JOIN users u ON iae.employee_id = u.id
LEFT JOIN installation_sub_tasks ist ON iwa.id = ist.assignment_id
GROUP BY iwa.id, c.id, assigned_by.id, verified_by.id;

-- Installation progress summary view
CREATE OR REPLACE VIEW installation_progress_summary AS
SELECT 
    iwa.id as assignment_id,
    iwa.customer_id,
    c.name as customer_name,
    iwa.status as assignment_status,
    COUNT(ist.id) as total_sub_tasks,
    COUNT(ist.id) FILTER (WHERE ist.status = 'pending') as pending_tasks,
    COUNT(ist.id) FILTER (WHERE ist.status = 'in_progress') as in_progress_tasks,
    COUNT(ist.id) FILTER (WHERE ist.status = 'completed') as completed_tasks,
    CASE 
        WHEN COUNT(ist.id) > 0 THEN 
            ROUND((COUNT(ist.id) FILTER (WHERE ist.status = 'completed')::decimal / COUNT(ist.id)) * 100, 2)
        ELSE 0 
    END as completion_percentage,
    MAX(ist.completed_at) as last_completed_task_at,
    MIN(ist.started_at) as first_started_task_at
FROM installation_work_assignments iwa
LEFT JOIN customers c ON iwa.customer_id = c.id
LEFT JOIN installation_sub_tasks ist ON iwa.id = ist.assignment_id
GROUP BY iwa.id, iwa.customer_id, c.name, iwa.status;

-- Function to create default sub-tasks for an assignment
CREATE OR REPLACE FUNCTION create_default_sub_tasks(assignment_id UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO installation_sub_tasks (assignment_id, sub_task_type)
    VALUES 
        (assignment_id, 'structure'),
        (assignment_id, 'panels'),
        (assignment_id, 'wiring_inverter'),
        (assignment_id, 'earthing'),
        (assignment_id, 'lightning_arrestor'),
        (assignment_id, 'data_collection')
    ON CONFLICT (assignment_id, sub_task_type) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- Function to get assignment completion percentage
CREATE OR REPLACE FUNCTION get_assignment_completion_percentage(assignment_id UUID)
RETURNS DECIMAL AS $$
DECLARE
    completion_percent DECIMAL;
BEGIN
    SELECT 
        CASE 
            WHEN COUNT(id) > 0 THEN 
                ROUND((COUNT(id) FILTER (WHERE status = 'completed')::decimal / COUNT(id)) * 100, 2)
            ELSE 0 
        END
    INTO completion_percent
    FROM installation_sub_tasks 
    WHERE assignment_id = $1;
    
    RETURN COALESCE(completion_percent, 0);
END;
$$ LANGUAGE plpgsql;

-- Trigger to create default sub-tasks when a new assignment is created
CREATE OR REPLACE FUNCTION trigger_create_default_sub_tasks()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM create_default_sub_tasks(NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_create_sub_tasks_on_assignment ON installation_work_assignments;
CREATE TRIGGER trigger_create_sub_tasks_on_assignment
    AFTER INSERT ON installation_work_assignments
    FOR EACH ROW
    EXECUTE FUNCTION trigger_create_default_sub_tasks();

-- Add Row Level Security (RLS) policies as mentioned in documentation

-- Enable RLS on all tables
ALTER TABLE installation_work_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE installation_assignment_employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE installation_sub_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE installation_task_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE installation_equipment_serials ENABLE ROW LEVEL SECURITY;
ALTER TABLE installation_task_team_members ENABLE ROW LEVEL SECURITY;

-- RLS Policy for installation_work_assignments
CREATE POLICY "Directors can access all installation assignments" ON installation_work_assignments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'director'
            AND users.status = 'active'
        )
    );

CREATE POLICY "Managers can access assignments in their office" ON installation_work_assignments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users u
            JOIN customers c ON installation_work_assignments.customer_id = c.id
            WHERE u.id = auth.uid() 
            AND u.role IN ('manager', 'lead')
            AND u.status = 'active'
            AND u.office_id = c.office_id
        )
    );

CREATE POLICY "Employees can access their assigned installations" ON installation_work_assignments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM installation_assignment_employees iae
            WHERE iae.assignment_id = installation_work_assignments.id
            AND iae.employee_id = auth.uid()
        )
        OR assigned_by_id = auth.uid()
    );

-- Similar policies for other tables...
CREATE POLICY "Users can access sub-tasks of their assignments" ON installation_sub_tasks
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM installation_work_assignments iwa
            WHERE iwa.id = installation_sub_tasks.assignment_id
            AND (
                -- Directors can access all
                EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'director' AND users.status = 'active')
                OR
                -- Managers/Leads can access in their office
                EXISTS (
                    SELECT 1 FROM users u
                    JOIN customers c ON iwa.customer_id = c.id
                    WHERE u.id = auth.uid() 
                    AND u.role IN ('manager', 'lead')
                    AND u.status = 'active'
                    AND u.office_id = c.office_id
                )
                OR
                -- Employees can access their assignments
                EXISTS (
                    SELECT 1 FROM installation_assignment_employees iae
                    WHERE iae.assignment_id = iwa.id
                    AND iae.employee_id = auth.uid()
                )
                OR iwa.assigned_by_id = auth.uid()
            )
        )
    );

-- Add comments
COMMENT ON TABLE installation_assignment_employees IS 'Many-to-many relationship between assignments and employees for team-based installations';
COMMENT ON TABLE installation_sub_tasks IS 'Individual task tracking with GPS coordinates and status progression';
COMMENT ON TABLE installation_task_photos IS 'Photo evidence for each sub-task with file storage integration';
COMMENT ON TABLE installation_equipment_serials IS 'Equipment serial numbers by sub-task with manufacturer details';
COMMENT ON TABLE installation_task_team_members IS 'Team member assignments per sub-task with role tracking';

-- Verify the new structure
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN (
    'installation_assignment_employees',
    'installation_sub_tasks', 
    'installation_task_photos',
    'installation_equipment_serials',
    'installation_task_team_members'
)
ORDER BY table_name, ordinal_position;
