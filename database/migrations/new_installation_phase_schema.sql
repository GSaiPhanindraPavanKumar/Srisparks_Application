-- New Installation Phase Database Schema - Complete Redesign
-- Date: 2025-09-03
-- Description: Modern, comprehensive installation management system with real-time capabilities

-- Drop existing installation tables (if you want to start fresh)
-- WARNING: This will delete all existing installation data
-- Uncomment these lines only if you want a complete fresh start
/*
DROP TABLE IF EXISTS public.installation_work_activities CASCADE;
DROP TABLE IF EXISTS public.installation_material_usage CASCADE;
DROP TABLE IF EXISTS public.installation_work_items CASCADE;
DROP TABLE IF EXISTS public.installation_projects CASCADE;
*/

-- Create enhanced installation projects table
CREATE TABLE IF NOT EXISTS public.installation_projects_v2 (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    project_code VARCHAR(50) UNIQUE NOT NULL DEFAULT CONCAT('INS-', EXTRACT(YEAR FROM NOW()), '-', LPAD(NEXTVAL('installation_project_sequence')::TEXT, 6, '0')),
    
    -- Customer Information
    customer_name VARCHAR(255) NOT NULL,
    customer_address TEXT NOT NULL,
    customer_phone VARCHAR(20),
    customer_email VARCHAR(255),
    
    -- Site Information
    site_latitude DECIMAL(10,8) NOT NULL,
    site_longitude DECIMAL(11,8) NOT NULL,
    site_address TEXT,
    site_access_instructions TEXT,
    geofence_radius DECIMAL(6,2) DEFAULT 100.0,
    
    -- Project Details
    system_capacity_kw DECIMAL(8,2) NOT NULL,
    estimated_duration_days INTEGER DEFAULT 7,
    actual_duration_days INTEGER,
    project_value DECIMAL(12,2),
    
    -- Status and Timeline
    status VARCHAR(50) DEFAULT 'planning' CHECK (status IN (
        'planning', 'scheduled', 'in_progress', 'quality_check', 
        'customer_review', 'completed', 'on_hold', 'cancelled'
    )),
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    
    scheduled_start_date DATE,
    actual_start_date DATE,
    estimated_completion_date DATE,
    actual_completion_date DATE,
    
    -- Progress Tracking
    overall_progress_percentage DECIMAL(5,2) DEFAULT 0.0 CHECK (overall_progress_percentage >= 0 AND overall_progress_percentage <= 100),
    total_phases INTEGER DEFAULT 0,
    completed_phases INTEGER DEFAULT 0,
    total_checkpoints INTEGER DEFAULT 0,
    passed_checkpoints INTEGER DEFAULT 0,
    
    -- Team Assignment
    project_manager_id UUID REFERENCES public.users(id),
    site_supervisor_id UUID REFERENCES public.users(id),
    assigned_office_id UUID REFERENCES public.offices(id),
    
    -- Quality and Safety
    quality_score DECIMAL(3,1) DEFAULT 0.0 CHECK (quality_score >= 0 AND quality_score <= 10),
    safety_incidents INTEGER DEFAULT 0,
    customer_satisfaction_score DECIMAL(3,1) CHECK (customer_satisfaction_score >= 0 AND customer_satisfaction_score <= 10),
    
    -- Documentation
    project_notes TEXT,
    special_requirements JSONB DEFAULT '[]'::jsonb,
    attachments JSONB DEFAULT '[]'::jsonb,
    
    -- Timestamps and Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES public.users(id),
    updated_by UUID REFERENCES public.users(id)
);

-- Create project sequence for unique project codes
CREATE SEQUENCE IF NOT EXISTS installation_project_sequence START 1;

-- Create installation work phases table (replaces work_items with better structure)
CREATE TABLE IF NOT EXISTS public.installation_work_phases (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES public.installation_projects_v2(id) ON DELETE CASCADE,
    
    -- Phase Information
    phase_code VARCHAR(20) NOT NULL, -- 'STRUCTURE', 'PANELS', 'ELECTRICAL', etc.
    phase_name VARCHAR(100) NOT NULL,
    phase_description TEXT,
    phase_order INTEGER NOT NULL,
    
    -- Dependencies
    prerequisite_phases JSONB DEFAULT '[]'::jsonb, -- Array of phase codes that must complete first
    
    -- Status and Progress
    status VARCHAR(50) DEFAULT 'not_started' CHECK (status IN (
        'not_started', 'planned', 'in_progress', 'quality_check', 
        'rework_required', 'completed', 'on_hold', 'cancelled'
    )),
    progress_percentage DECIMAL(5,2) DEFAULT 0.0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    
    -- Timeline
    estimated_start_date DATE,
    actual_start_date DATE,
    estimated_duration_hours DECIMAL(6,2),
    actual_duration_hours DECIMAL(6,2) DEFAULT 0,
    estimated_completion_date DATE,
    actual_completion_date DATE,
    
    -- Team Assignment
    lead_technician_id UUID REFERENCES public.users(id),
    assigned_team_members JSONB DEFAULT '[]'::jsonb, -- Array of user IDs
    required_skills JSONB DEFAULT '[]'::jsonb, -- Array of skill requirements
    
    -- Location and Safety
    work_location_description TEXT,
    safety_requirements JSONB DEFAULT '[]'::jsonb,
    required_equipment JSONB DEFAULT '[]'::jsonb,
    
    -- Quality Control
    quality_checkpoints JSONB DEFAULT '[]'::jsonb,
    passed_checkpoints JSONB DEFAULT '[]'::jsonb,
    quality_score DECIMAL(3,1) CHECK (quality_score >= 0 AND quality_score <= 10),
    
    -- Materials and Resources
    required_materials JSONB DEFAULT '[]'::jsonb,
    allocated_materials JSONB DEFAULT '[]'::jsonb,
    used_materials JSONB DEFAULT '[]'::jsonb,
    
    -- Documentation
    work_instructions TEXT,
    completion_notes TEXT,
    phase_photos JSONB DEFAULT '[]'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES public.users(id),
    updated_by UUID REFERENCES public.users(id),
    
    -- Constraints
    UNIQUE(project_id, phase_code)
);

-- Create installation teams table for better team management
CREATE TABLE IF NOT EXISTS public.installation_teams (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES public.installation_projects_v2(id) ON DELETE CASCADE,
    
    -- Team Information
    team_name VARCHAR(100) NOT NULL,
    team_type VARCHAR(50) DEFAULT 'general' CHECK (team_type IN (
        'general', 'specialized', 'emergency', 'quality_control'
    )),
    
    -- Team Composition
    team_lead_id UUID NOT NULL REFERENCES public.users(id),
    team_members JSONB DEFAULT '[]'::jsonb, -- Array of user objects with roles
    backup_members JSONB DEFAULT '[]'::jsonb,
    
    -- Team Capabilities
    skill_matrix JSONB DEFAULT '{}'::jsonb, -- Skills and proficiency levels
    certifications JSONB DEFAULT '[]'::jsonb,
    equipment_assigned JSONB DEFAULT '[]'::jsonb,
    
    -- Work Assignment
    assigned_phases JSONB DEFAULT '[]'::jsonb, -- Array of phase IDs
    current_workload DECIMAL(5,2) DEFAULT 0.0, -- Percentage of capacity
    availability_status VARCHAR(20) DEFAULT 'available' CHECK (availability_status IN (
        'available', 'busy', 'break', 'offline', 'emergency'
    )),
    
    -- Performance Metrics
    completed_phases INTEGER DEFAULT 0,
    average_quality_score DECIMAL(3,1) DEFAULT 0.0,
    on_time_completion_rate DECIMAL(5,2) DEFAULT 0.0,
    
    -- Location and Communication
    last_known_location JSONB DEFAULT '{}'::jsonb, -- {lat, lng, timestamp}
    communication_preferences JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES public.users(id)
);

-- Create installation checkpoints table for quality control
CREATE TABLE IF NOT EXISTS public.installation_checkpoints (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES public.installation_projects_v2(id) ON DELETE CASCADE,
    phase_id UUID NOT NULL REFERENCES public.installation_work_phases(id) ON DELETE CASCADE,
    
    -- Checkpoint Information
    checkpoint_code VARCHAR(20) NOT NULL,
    checkpoint_name VARCHAR(100) NOT NULL,
    checkpoint_description TEXT,
    checkpoint_type VARCHAR(20) DEFAULT 'quality' CHECK (checkpoint_type IN (
        'quality', 'safety', 'milestone', 'customer_approval', 'regulatory'
    )),
    
    -- Requirements
    is_mandatory BOOLEAN DEFAULT true,
    requires_photo BOOLEAN DEFAULT false,
    requires_signature BOOLEAN DEFAULT false,
    requires_measurement BOOLEAN DEFAULT false,
    
    -- Criteria and Standards
    acceptance_criteria JSONB DEFAULT '[]'::jsonb,
    measurement_parameters JSONB DEFAULT '[]'::jsonb,
    pass_threshold JSONB DEFAULT '{}'::jsonb,
    
    -- Status and Results
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN (
        'pending', 'in_review', 'passed', 'failed', 'waived'
    )),
    result_score DECIMAL(5,2) CHECK (result_score >= 0 AND result_score <= 100),
    result_notes TEXT,
    failure_reasons JSONB DEFAULT '[]'::jsonb,
    
    -- Verification
    verified_by UUID REFERENCES public.users(id),
    verified_at TIMESTAMP WITH TIME ZONE,
    verification_method VARCHAR(50),
    verification_evidence JSONB DEFAULT '[]'::jsonb, -- Photos, documents, etc.
    
    -- Measurements and Data
    measurements JSONB DEFAULT '{}'::jsonb,
    test_results JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(phase_id, checkpoint_code)
);

-- Create installation activities table for comprehensive logging
CREATE TABLE IF NOT EXISTS public.installation_activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES public.installation_projects_v2(id) ON DELETE CASCADE,
    phase_id UUID REFERENCES public.installation_work_phases(id) ON DELETE CASCADE,
    team_id UUID REFERENCES public.installation_teams(id) ON DELETE CASCADE,
    
    -- Activity Information
    activity_type VARCHAR(50) NOT NULL CHECK (activity_type IN (
        'project_started', 'project_completed', 'phase_started', 'phase_completed',
        'checkpoint_passed', 'checkpoint_failed', 'team_assigned', 'team_reassigned',
        'material_delivered', 'material_used', 'issue_reported', 'issue_resolved',
        'customer_communication', 'safety_incident', 'quality_review',
        'location_check', 'break_started', 'break_ended', 'shift_started', 'shift_ended'
    )),
    activity_title VARCHAR(200) NOT NULL,
    activity_description TEXT,
    
    -- Actor and Target
    performed_by UUID NOT NULL REFERENCES public.users(id),
    affected_user_id UUID REFERENCES public.users(id),
    
    -- Location and Time
    activity_location JSONB DEFAULT '{}'::jsonb, -- {lat, lng, address}
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    duration_minutes INTEGER,
    
    -- Context and Metadata
    activity_context JSONB DEFAULT '{}'::jsonb, -- Flexible data storage
    attachments JSONB DEFAULT '[]'::jsonb, -- Photos, documents
    tags JSONB DEFAULT '[]'::jsonb, -- Searchable tags
    
    -- Status and Visibility
    activity_status VARCHAR(20) DEFAULT 'completed' CHECK (activity_status IN (
        'in_progress', 'completed', 'cancelled', 'failed'
    )),
    is_milestone BOOLEAN DEFAULT false,
    visibility VARCHAR(20) DEFAULT 'team' CHECK (visibility IN (
        'private', 'team', 'project', 'management', 'public'
    )),
    
    -- Integration
    external_reference VARCHAR(100), -- For integrations
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN (
        'pending', 'synced', 'failed', 'retry'
    )),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create installation resources table for equipment and material tracking
CREATE TABLE IF NOT EXISTS public.installation_resources (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES public.installation_projects_v2(id) ON DELETE CASCADE,
    phase_id UUID REFERENCES public.installation_work_phases(id) ON DELETE CASCADE,
    
    -- Resource Information
    resource_type VARCHAR(20) NOT NULL CHECK (resource_type IN (
        'material', 'equipment', 'tool', 'vehicle', 'consumable'
    )),
    resource_code VARCHAR(50),
    resource_name VARCHAR(200) NOT NULL,
    resource_description TEXT,
    
    -- Quantities and Units
    required_quantity DECIMAL(10,3) NOT NULL,
    allocated_quantity DECIMAL(10,3) DEFAULT 0,
    used_quantity DECIMAL(10,3) DEFAULT 0,
    returned_quantity DECIMAL(10,3) DEFAULT 0,
    unit VARCHAR(20) NOT NULL,
    
    -- Cost and Value
    unit_cost DECIMAL(10,2),
    total_allocated_cost DECIMAL(12,2),
    total_used_cost DECIMAL(12,2),
    
    -- Status and Tracking
    status VARCHAR(20) DEFAULT 'required' CHECK (status IN (
        'required', 'ordered', 'allocated', 'delivered', 'in_use', 'returned', 'consumed'
    )),
    criticality VARCHAR(20) DEFAULT 'normal' CHECK (criticality IN (
        'low', 'normal', 'high', 'critical'
    )),
    
    -- Supplier and Logistics
    supplier_name VARCHAR(200),
    supplier_reference VARCHAR(100),
    delivery_date DATE,
    delivery_location TEXT,
    
    -- Assignment and Usage
    assigned_to_team_id UUID REFERENCES public.installation_teams(id),
    assigned_to_user_id UUID REFERENCES public.users(id),
    usage_start_date DATE,
    usage_end_date DATE,
    
    -- Quality and Condition
    condition_on_delivery VARCHAR(20) DEFAULT 'good' CHECK (condition_on_delivery IN (
        'excellent', 'good', 'fair', 'poor', 'damaged'
    )),
    condition_on_return VARCHAR(20) CHECK (condition_on_return IN (
        'excellent', 'good', 'fair', 'poor', 'damaged', 'lost'
    )),
    quality_notes TEXT,
    
    -- Documentation
    specifications JSONB DEFAULT '{}'::jsonb,
    usage_instructions TEXT,
    maintenance_requirements TEXT,
    attachments JSONB DEFAULT '[]'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES public.users(id),
    updated_by UUID REFERENCES public.users(id)
);

-- Create installation communications table for team collaboration
CREATE TABLE IF NOT EXISTS public.installation_communications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES public.installation_projects_v2(id) ON DELETE CASCADE,
    phase_id UUID REFERENCES public.installation_work_phases(id) ON DELETE CASCADE,
    
    -- Communication Information
    communication_type VARCHAR(20) NOT NULL CHECK (communication_type IN (
        'message', 'announcement', 'alert', 'escalation', 'update', 'question', 'issue'
    )),
    subject VARCHAR(200),
    message_content TEXT NOT NULL,
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN (
        'low', 'normal', 'high', 'urgent', 'emergency'
    )),
    
    -- Participants
    sender_id UUID NOT NULL REFERENCES public.users(id),
    recipient_ids JSONB DEFAULT '[]'::jsonb, -- Array of user IDs
    cc_recipient_ids JSONB DEFAULT '[]'::jsonb,
    
    -- Thread and Responses
    parent_message_id UUID REFERENCES public.installation_communications(id),
    is_reply BOOLEAN DEFAULT false,
    reply_count INTEGER DEFAULT 0,
    
    -- Status and Tracking
    message_status VARCHAR(20) DEFAULT 'sent' CHECK (message_status IN (
        'draft', 'sent', 'delivered', 'read', 'replied', 'resolved'
    )),
    requires_response BOOLEAN DEFAULT false,
    response_deadline TIMESTAMP WITH TIME ZONE,
    
    -- Delivery and Read Receipts
    delivery_receipts JSONB DEFAULT '{}'::jsonb, -- {user_id: timestamp}
    read_receipts JSONB DEFAULT '{}'::jsonb,
    
    -- Attachments and Media
    attachments JSONB DEFAULT '[]'::jsonb,
    has_attachments BOOLEAN DEFAULT false,
    
    -- Location Context
    location_context JSONB DEFAULT '{}'::jsonb,
    
    -- Integration
    external_channel VARCHAR(20) CHECK (external_channel IN (
        'app', 'email', 'sms', 'whatsapp', 'phone'
    )),
    external_reference VARCHAR(100),
    
    -- Timestamps
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create comprehensive indexes for performance
CREATE INDEX IF NOT EXISTS idx_installation_projects_v2_customer ON public.installation_projects_v2(customer_id);
CREATE INDEX IF NOT EXISTS idx_installation_projects_v2_status ON public.installation_projects_v2(status);
CREATE INDEX IF NOT EXISTS idx_installation_projects_v2_office ON public.installation_projects_v2(assigned_office_id);
CREATE INDEX IF NOT EXISTS idx_installation_projects_v2_dates ON public.installation_projects_v2(scheduled_start_date, estimated_completion_date);
CREATE INDEX IF NOT EXISTS idx_installation_projects_v2_location ON public.installation_projects_v2(site_latitude, site_longitude);

CREATE INDEX IF NOT EXISTS idx_installation_work_phases_project ON public.installation_work_phases(project_id);
CREATE INDEX IF NOT EXISTS idx_installation_work_phases_status ON public.installation_work_phases(status);
CREATE INDEX IF NOT EXISTS idx_installation_work_phases_lead ON public.installation_work_phases(lead_technician_id);
CREATE INDEX IF NOT EXISTS idx_installation_work_phases_order ON public.installation_work_phases(project_id, phase_order);

CREATE INDEX IF NOT EXISTS idx_installation_teams_project ON public.installation_teams(project_id);
CREATE INDEX IF NOT EXISTS idx_installation_teams_lead ON public.installation_teams(team_lead_id);
CREATE INDEX IF NOT EXISTS idx_installation_teams_status ON public.installation_teams(availability_status);

CREATE INDEX IF NOT EXISTS idx_installation_checkpoints_phase ON public.installation_checkpoints(phase_id);
CREATE INDEX IF NOT EXISTS idx_installation_checkpoints_type ON public.installation_checkpoints(checkpoint_type);
CREATE INDEX IF NOT EXISTS idx_installation_checkpoints_status ON public.installation_checkpoints(status);

CREATE INDEX IF NOT EXISTS idx_installation_activities_project ON public.installation_activities(project_id);
CREATE INDEX IF NOT EXISTS idx_installation_activities_type ON public.installation_activities(activity_type);
CREATE INDEX IF NOT EXISTS idx_installation_activities_user ON public.installation_activities(performed_by);
CREATE INDEX IF NOT EXISTS idx_installation_activities_timestamp ON public.installation_activities(timestamp);

CREATE INDEX IF NOT EXISTS idx_installation_resources_project ON public.installation_resources(project_id);
CREATE INDEX IF NOT EXISTS idx_installation_resources_type ON public.installation_resources(resource_type);
CREATE INDEX IF NOT EXISTS idx_installation_resources_status ON public.installation_resources(status);

CREATE INDEX IF NOT EXISTS idx_installation_communications_project ON public.installation_communications(project_id);
CREATE INDEX IF NOT EXISTS idx_installation_communications_sender ON public.installation_communications(sender_id);
CREATE INDEX IF NOT EXISTS idx_installation_communications_type ON public.installation_communications(communication_type);

-- Create updated_at triggers for all tables
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_installation_projects_v2_updated_at 
    BEFORE UPDATE ON public.installation_projects_v2 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_installation_work_phases_updated_at 
    BEFORE UPDATE ON public.installation_work_phases 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_installation_resources_updated_at 
    BEFORE UPDATE ON public.installation_resources 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE public.installation_projects_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.installation_work_phases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.installation_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.installation_checkpoints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.installation_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.installation_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.installation_communications ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for office-based access control
CREATE POLICY "Users can access projects from their office" ON public.installation_projects_v2
    FOR ALL USING (
        assigned_office_id IN (
            SELECT office_id FROM public.users WHERE id = auth.uid()
        ) OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('director')
        )
    );

-- Similar policies for other tables
CREATE POLICY "Users can access phases from their office projects" ON public.installation_work_phases
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.installation_projects_v2 ip
            WHERE ip.id = project_id 
            AND (
                ip.assigned_office_id IN (
                    SELECT office_id FROM public.users WHERE id = auth.uid()
                ) OR
                EXISTS (
                    SELECT 1 FROM public.users 
                    WHERE id = auth.uid() 
                    AND role IN ('director')
                )
            )
        )
    );

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON public.installation_projects_v2 TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.installation_work_phases TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.installation_teams TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.installation_checkpoints TO authenticated;
GRANT SELECT, INSERT ON public.installation_activities TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.installation_resources TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.installation_communications TO authenticated;

-- Create default installation phases template
INSERT INTO public.installation_work_phases (
    project_id, phase_code, phase_name, phase_description, phase_order, 
    estimated_duration_hours, required_skills, safety_requirements, quality_checkpoints
) VALUES 
-- Note: These will be inserted when creating projects, just showing template
-- ('FOUNDATION', 'Foundation & Structure', 'Site preparation and mounting structure installation', 1, 16.0, '["structural", "measurement"]', '["safety_gear", "fall_protection"]', '["foundation_level", "structure_alignment"]'),
-- ('PANELS', 'Solar Panel Installation', 'Solar panel mounting and initial connections', 2, 24.0, '["electrical", "panel_handling"]', '["safety_gear", "electrical_safety"]', '["panel_alignment", "connection_check"]'),
-- ('ELECTRICAL', 'Electrical & Wiring', 'Inverter installation and electrical connections', 3, 20.0, '["electrical", "inverter"]', '["electrical_safety", "lockout_tagout"]', '["wiring_check", "inverter_config"]'),
-- ('EARTHING', 'Earthing & Grounding', 'Grounding system installation', 4, 8.0, '["electrical", "grounding"]', '["electrical_safety"]', '["earth_resistance", "continuity_check"]'),
-- ('PROTECTION', 'Lightning Protection', 'Lightning arrestor and surge protection', 5, 6.0, '["electrical", "protection"]', '["electrical_safety", "height_safety"]', '["protection_test", "surge_rating"]'),
-- ('TESTING', 'System Testing', 'Complete system testing and commissioning', 6, 12.0, '["electrical", "testing", "commissioning"]', '["electrical_safety"]', '["performance_test", "safety_test"]');

-- Add comments for documentation
COMMENT ON TABLE public.installation_projects_v2 IS 'Enhanced installation projects with comprehensive tracking and real-time capabilities';
COMMENT ON TABLE public.installation_work_phases IS 'Structured work phases with dependencies and quality control';
COMMENT ON TABLE public.installation_teams IS 'Team management with skills tracking and performance metrics';
COMMENT ON TABLE public.installation_checkpoints IS 'Quality control checkpoints with verification requirements';
COMMENT ON TABLE public.installation_activities IS 'Comprehensive activity logging for audit and tracking';
COMMENT ON TABLE public.installation_resources IS 'Resource and material tracking with cost management';
COMMENT ON TABLE public.installation_communications IS 'Team communication and collaboration system';

SELECT 'New Installation Phase database schema created successfully!' as result;
