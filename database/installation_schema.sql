-- Installation Work Management Database Schema
-- This script creates all necessary tables for the Installation Phase workflow

-- =====================================
-- 1. Installation Work Assignments Table
-- =====================================
CREATE TABLE installation_work_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    assigned_by_id UUID NOT NULL REFERENCES users(id),
    status VARCHAR(20) NOT NULL DEFAULT 'assigned' CHECK (status IN ('assigned', 'in_progress', 'completed', 'verified', 'rejected')),
    assigned_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    scheduled_date DATE,
    completed_date TIMESTAMP WITH TIME ZONE,
    verified_date TIMESTAMP WITH TIME ZONE,
    verified_by_id UUID REFERENCES users(id),
    verification_remarks TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- =====================================
-- 2. Installation Assignment Employees (Many-to-Many)
-- =====================================
CREATE TABLE installation_assignment_employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID NOT NULL REFERENCES installation_work_assignments(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(assignment_id, employee_id)
);

-- =====================================
-- 3. Installation Sub Tasks Table
-- =====================================
CREATE TABLE installation_sub_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID NOT NULL REFERENCES installation_work_assignments(id) ON DELETE CASCADE,
    sub_task VARCHAR(30) NOT NULL CHECK (sub_task IN ('structure', 'panels', 'wiring_inverter', 'earthing', 'lightning_arrestor', 'data_collection')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
    started_by_id UUID REFERENCES users(id),
    started_date TIMESTAMP WITH TIME ZONE,
    start_gps_latitude DECIMAL(10, 8),
    start_gps_longitude DECIMAL(11, 8),
    start_gps_accuracy DECIMAL(5, 2),
    completed_by_id UUID REFERENCES users(id),
    completed_date TIMESTAMP WITH TIME ZONE,
    completion_gps_latitude DECIMAL(10, 8),
    completion_gps_longitude DECIMAL(11, 8),
    completion_gps_accuracy DECIMAL(5, 2),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(assignment_id, sub_task)
);

-- =====================================
-- 4. Installation Task Photos Table
-- =====================================
CREATE TABLE installation_task_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_task_id UUID NOT NULL REFERENCES installation_sub_tasks(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INTEGER,
    mime_type VARCHAR(100),
    uploaded_by_id UUID NOT NULL REFERENCES users(id),
    upload_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- =====================================
-- 5. Installation Equipment Serial Numbers Table
-- =====================================
CREATE TABLE installation_equipment_serials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_task_id UUID NOT NULL REFERENCES installation_sub_tasks(id) ON DELETE CASCADE,
    equipment_type VARCHAR(50) NOT NULL, -- 'panel', 'inverter', 'battery', 'meter', etc.
    serial_number VARCHAR(100) NOT NULL,
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    specifications JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(sub_task_id, equipment_type, serial_number)
);

-- =====================================
-- 6. Installation Team Members Table (for each sub-task)
-- =====================================
CREATE TABLE installation_task_team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sub_task_id UUID NOT NULL REFERENCES installation_sub_tasks(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(30), -- 'lead', 'member', 'assistant'
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(sub_task_id, employee_id)
);

-- =====================================
-- Indexes for Performance
-- =====================================

-- Installation assignments indexes
CREATE INDEX idx_installation_assignments_customer_id ON installation_work_assignments(customer_id);
CREATE INDEX idx_installation_assignments_assigned_by ON installation_work_assignments(assigned_by_id);
CREATE INDEX idx_installation_assignments_status ON installation_work_assignments(status);
CREATE INDEX idx_installation_assignments_assigned_date ON installation_work_assignments(assigned_date);
CREATE INDEX idx_installation_assignments_scheduled_date ON installation_work_assignments(scheduled_date);

-- Assignment employees indexes
CREATE INDEX idx_installation_assignment_employees_assignment ON installation_assignment_employees(assignment_id);
CREATE INDEX idx_installation_assignment_employees_employee ON installation_assignment_employees(employee_id);

-- Sub tasks indexes
CREATE INDEX idx_installation_sub_tasks_assignment ON installation_sub_tasks(assignment_id);
CREATE INDEX idx_installation_sub_tasks_status ON installation_sub_tasks(status);
CREATE INDEX idx_installation_sub_tasks_sub_task ON installation_sub_tasks(sub_task);
CREATE INDEX idx_installation_sub_tasks_started_by ON installation_sub_tasks(started_by_id);
CREATE INDEX idx_installation_sub_tasks_completed_by ON installation_sub_tasks(completed_by_id);

-- Photos indexes
CREATE INDEX idx_installation_task_photos_sub_task ON installation_task_photos(sub_task_id);
CREATE INDEX idx_installation_task_photos_uploaded_by ON installation_task_photos(uploaded_by_id);

-- Equipment serials indexes
CREATE INDEX idx_installation_equipment_serials_sub_task ON installation_equipment_serials(sub_task_id);
CREATE INDEX idx_installation_equipment_serials_type ON installation_equipment_serials(equipment_type);
CREATE INDEX idx_installation_equipment_serials_serial ON installation_equipment_serials(serial_number);

-- Team members indexes
CREATE INDEX idx_installation_task_team_members_sub_task ON installation_task_team_members(sub_task_id);
CREATE INDEX idx_installation_task_team_members_employee ON installation_task_team_members(employee_id);

-- =====================================
-- Triggers for updated_at columns
-- =====================================

-- Function to update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_installation_work_assignments_updated_at 
    BEFORE UPDATE ON installation_work_assignments 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_installation_sub_tasks_updated_at 
    BEFORE UPDATE ON installation_sub_tasks 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================
-- Views for Common Queries
-- =====================================

-- View for assignment details with customer and employee information
CREATE VIEW installation_assignment_details AS
SELECT 
    iwa.id,
    iwa.status,
    iwa.assigned_date,
    iwa.scheduled_date,
    iwa.completed_date,
    iwa.verified_date,
    iwa.notes,
    c.name as customer_name,
    c.address as customer_address,
    c.city as customer_city,
    c.zip_code as customer_pincode,
    c.latitude as customer_latitude,
    c.longitude as customer_longitude,
    c.amount_kw as system_capacity,
    assigned_by.full_name as assigned_by_name,
    verified_by.full_name as verified_by_name,
    iwa.verification_remarks,
    ARRAY_AGG(emp.full_name ORDER BY emp.full_name) as assigned_employee_names,
    ARRAY_AGG(emp.id ORDER BY emp.full_name) as assigned_employee_ids
FROM installation_work_assignments iwa
JOIN customers c ON iwa.customer_id = c.id
JOIN users assigned_by ON iwa.assigned_by_id = assigned_by.id
LEFT JOIN users verified_by ON iwa.verified_by_id = verified_by.id
JOIN installation_assignment_employees iae ON iwa.id = iae.assignment_id
JOIN users emp ON iae.employee_id = emp.id
GROUP BY 
    iwa.id, iwa.status, iwa.assigned_date, iwa.scheduled_date, iwa.completed_date, 
    iwa.verified_date, iwa.notes, c.name, c.address, c.city, c.zip_code, 
    c.latitude, c.longitude, c.amount_kw, assigned_by.full_name, 
    verified_by.full_name, iwa.verification_remarks;

-- View for sub-task progress
CREATE VIEW installation_progress_summary AS
SELECT 
    assignment_id,
    COUNT(*) as total_sub_tasks,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_sub_tasks,
    ROUND(
        (COUNT(CASE WHEN status = 'completed' THEN 1 END)::DECIMAL / COUNT(*)) * 100, 
        2
    ) as completion_percentage,
    MIN(started_date) as first_task_started,
    MAX(completed_date) as last_task_completed
FROM installation_sub_tasks
GROUP BY assignment_id;

-- View for installation statistics
CREATE VIEW installation_statistics AS
SELECT 
    u.office_id,
    COUNT(*) as total_assignments,
    COUNT(CASE WHEN iwa.status = 'assigned' THEN 1 END) as assigned_count,
    COUNT(CASE WHEN iwa.status = 'in_progress' THEN 1 END) as in_progress_count,
    COUNT(CASE WHEN iwa.status = 'completed' THEN 1 END) as completed_count,
    COUNT(CASE WHEN iwa.status = 'verified' THEN 1 END) as verified_count,
    COUNT(CASE WHEN iwa.status = 'rejected' THEN 1 END) as rejected_count,
    AVG(CASE WHEN iwa.completed_date IS NOT NULL AND iwa.assigned_date IS NOT NULL 
        THEN EXTRACT(DAYS FROM (iwa.completed_date - iwa.assigned_date)) 
        END) as avg_completion_days
FROM installation_work_assignments iwa
JOIN users u ON iwa.assigned_by_id = u.id
GROUP BY u.office_id

UNION ALL

-- Global statistics (all offices combined)
SELECT 
    NULL as office_id,
    COUNT(*) as total_assignments,
    COUNT(CASE WHEN iwa.status = 'assigned' THEN 1 END) as assigned_count,
    COUNT(CASE WHEN iwa.status = 'in_progress' THEN 1 END) as in_progress_count,
    COUNT(CASE WHEN iwa.status = 'completed' THEN 1 END) as completed_count,
    COUNT(CASE WHEN iwa.status = 'verified' THEN 1 END) as verified_count,
    COUNT(CASE WHEN iwa.status = 'rejected' THEN 1 END) as rejected_count,
    AVG(CASE WHEN iwa.completed_date IS NOT NULL AND iwa.assigned_date IS NOT NULL 
        THEN EXTRACT(DAYS FROM (iwa.completed_date - iwa.assigned_date)) 
        END) as avg_completion_days
FROM installation_work_assignments iwa
JOIN users u ON iwa.assigned_by_id = u.id;

-- =====================================
-- Row Level Security (RLS) Policies
-- =====================================

-- Enable RLS on tables
ALTER TABLE installation_work_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE installation_assignment_employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE installation_sub_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE installation_task_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE installation_equipment_serials ENABLE ROW LEVEL SECURITY;
ALTER TABLE installation_task_team_members ENABLE ROW LEVEL SECURITY;

-- Policy for Directors (can see all)
CREATE POLICY "Directors can manage all installations" ON installation_work_assignments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'director'
        )
    );

-- Policy for Managers and Leads (can see their office)
CREATE POLICY "Managers and Leads can manage office installations" ON installation_work_assignments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users u1
            JOIN users u2 ON u1.office_id = u2.office_id
            WHERE u1.id = auth.uid() 
            AND u1.role IN ('manager', 'lead')
            AND u2.id = assigned_by_id
        )
    );

-- Policy for Employees (can see assigned installations)
CREATE POLICY "Employees can see assigned installations" ON installation_work_assignments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM installation_assignment_employees iae
            WHERE iae.assignment_id = id 
            AND iae.employee_id = auth.uid()
        )
    );

-- Similar policies for related tables...
CREATE POLICY "Installation employees access" ON installation_assignment_employees
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM installation_work_assignments iwa
            JOIN users u ON u.id = auth.uid()
            WHERE iwa.id = assignment_id
            AND (
                u.role = 'director'
                OR (u.role IN ('manager', 'lead') AND EXISTS (
                    SELECT 1 FROM users assigned_by 
                    WHERE assigned_by.id = iwa.assigned_by_id 
                    AND assigned_by.office_id = u.office_id
                ))
                OR employee_id = auth.uid()
            )
        )
    );

-- =====================================
-- Functions for Common Operations
-- =====================================

-- Function to create installation assignment with sub-tasks
CREATE OR REPLACE FUNCTION create_installation_assignment(
    p_customer_id UUID,
    p_assigned_by_id UUID,
    p_employee_ids UUID[],
    p_scheduled_date DATE DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_assignment_id UUID;
    v_employee_id UUID;
    v_sub_task TEXT;
BEGIN
    -- Create the assignment
    INSERT INTO installation_work_assignments (
        customer_id, assigned_by_id, scheduled_date, notes
    ) VALUES (
        p_customer_id, p_assigned_by_id, p_scheduled_date, p_notes
    ) RETURNING id INTO v_assignment_id;
    
    -- Assign employees
    FOREACH v_employee_id IN ARRAY p_employee_ids
    LOOP
        INSERT INTO installation_assignment_employees (assignment_id, employee_id)
        VALUES (v_assignment_id, v_employee_id);
    END LOOP;
    
    -- Create sub-tasks
    FOREACH v_sub_task IN ARRAY ARRAY['structure', 'panels', 'wiring_inverter', 'earthing', 'lightning_arrestor', 'data_collection']
    LOOP
        INSERT INTO installation_sub_tasks (assignment_id, sub_task)
        VALUES (v_assignment_id, v_sub_task);
    END LOOP;
    
    RETURN v_assignment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate completion percentage
CREATE OR REPLACE FUNCTION get_assignment_completion_percentage(p_assignment_id UUID)
RETURNS DECIMAL AS $$
DECLARE
    v_total_tasks INTEGER;
    v_completed_tasks INTEGER;
BEGIN
    SELECT 
        COUNT(*),
        COUNT(CASE WHEN status = 'completed' THEN 1 END)
    INTO v_total_tasks, v_completed_tasks
    FROM installation_sub_tasks
    WHERE assignment_id = p_assignment_id;
    
    IF v_total_tasks = 0 THEN
        RETURN 0;
    END IF;
    
    RETURN ROUND((v_completed_tasks::DECIMAL / v_total_tasks) * 100, 2);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================
-- Sample Data (for testing)
-- =====================================

-- Note: This section would contain sample data for testing purposes
-- It should be commented out or removed in production

/*
-- Sample installation assignment
DO $$
DECLARE
    v_customer_id UUID;
    v_manager_id UUID;
    v_employee_ids UUID[];
BEGIN
    -- Get sample customer and users (assuming they exist)
    SELECT id INTO v_customer_id FROM customers LIMIT 1;
    SELECT id INTO v_manager_id FROM users WHERE role = 'manager' LIMIT 1;
    SELECT ARRAY_AGG(id) INTO v_employee_ids FROM users WHERE role = 'employee' LIMIT 2;
    
    -- Create sample assignment if data exists
    IF v_customer_id IS NOT NULL AND v_manager_id IS NOT NULL AND array_length(v_employee_ids, 1) > 0 THEN
        PERFORM create_installation_assignment(
            v_customer_id,
            v_manager_id,
            v_employee_ids,
            CURRENT_DATE + INTERVAL '7 days',
            'Priority installation - Customer requested early completion'
        );
    END IF;
END $$;
*/
