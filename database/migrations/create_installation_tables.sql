-- Migration: Create Installation Management Tables
-- Date: 2025-09-03
-- Description: Creates tables for installation project management with team tracking and location verification

-- Create installation_projects table
CREATE TABLE IF NOT EXISTS public.installation_projects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    customer_name VARCHAR(255) NOT NULL,
    customer_address TEXT NOT NULL,
    site_latitude DECIMAL(10,8) NOT NULL,
    site_longitude DECIMAL(11,8) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'on_hold')),
    assigned_manager_id UUID REFERENCES public.users(id),
    start_date DATE,
    target_completion_date DATE,
    actual_completion_date DATE,
    total_work_items INTEGER DEFAULT 0,
    completed_work_items INTEGER DEFAULT 0,
    notes TEXT,
    created_by UUID REFERENCES public.users(id),
    updated_by UUID REFERENCES public.users(id)
);

-- Create installation_work_items table
CREATE TABLE IF NOT EXISTS public.installation_work_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL REFERENCES public.installation_projects(id) ON DELETE CASCADE,
    work_type VARCHAR(50) NOT NULL CHECK (work_type IN ('structure_work', 'panels', 'inverter_wiring', 'earthing', 'lightning_arrestor')),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'not_started' CHECK (status IN ('not_started', 'assigned', 'in_progress', 'verification_pending', 'completed', 'on_hold')),
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    estimated_hours DECIMAL(5,2),
    actual_hours DECIMAL(5,2) DEFAULT 0,
    lead_employee_id UUID REFERENCES public.users(id),
    team_member_ids JSONB DEFAULT '[]'::jsonb,
    assigned_date TIMESTAMP WITH TIME ZONE,
    started_date TIMESTAMP WITH TIME ZONE,
    completed_date TIMESTAMP WITH TIME ZONE,
    verified_by UUID REFERENCES public.users(id),
    verified_date TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES public.users(id),
    approved_date TIMESTAMP WITH TIME ZONE,
    location_lat DECIMAL(10,8),
    location_lng DECIMAL(11,8),
    location_radius DECIMAL(6,2) DEFAULT 100.0,
    required_materials JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES public.users(id),
    updated_by UUID REFERENCES public.users(id)
);

-- Create installation_material_usage table
CREATE TABLE IF NOT EXISTS public.installation_material_usage (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    work_item_id UUID NOT NULL REFERENCES public.installation_work_items(id) ON DELETE CASCADE,
    material_name VARCHAR(255) NOT NULL,
    required_quantity DECIMAL(10,3) NOT NULL,
    used_quantity DECIMAL(10,3) DEFAULT 0,
    variance_quantity DECIMAL(10,3) DEFAULT 0,
    unit VARCHAR(50) NOT NULL,
    cost_per_unit DECIMAL(10,2),
    total_cost DECIMAL(12,2),
    supplier VARCHAR(255),
    notes TEXT,
    recorded_by UUID REFERENCES public.users(id),
    recorded_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    verified_by UUID REFERENCES public.users(id),
    verified_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create installation_work_activities table
CREATE TABLE IF NOT EXISTS public.installation_work_activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    work_item_id UUID NOT NULL REFERENCES public.installation_work_items(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES public.users(id),
    activity_type VARCHAR(50) NOT NULL CHECK (activity_type IN ('start_work', 'stop_work', 'break_start', 'break_end', 'location_update', 'material_usage', 'status_update')),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    location_lat DECIMAL(10,8),
    location_lng DECIMAL(11,8),
    location_accuracy DECIMAL(6,2),
    is_within_site BOOLEAN DEFAULT false,
    distance_from_site DECIMAL(8,2),
    description TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_installation_projects_customer_id ON public.installation_projects(customer_id);
CREATE INDEX IF NOT EXISTS idx_installation_projects_status ON public.installation_projects(status);
CREATE INDEX IF NOT EXISTS idx_installation_projects_assigned_manager ON public.installation_projects(assigned_manager_id);
CREATE INDEX IF NOT EXISTS idx_installation_projects_customer_name ON public.installation_projects(customer_name);
CREATE INDEX IF NOT EXISTS idx_installation_projects_location ON public.installation_projects(site_latitude, site_longitude);

CREATE INDEX IF NOT EXISTS idx_installation_work_items_project_id ON public.installation_work_items(project_id);
CREATE INDEX IF NOT EXISTS idx_installation_work_items_work_type ON public.installation_work_items(work_type);
CREATE INDEX IF NOT EXISTS idx_installation_work_items_status ON public.installation_work_items(status);
CREATE INDEX IF NOT EXISTS idx_installation_work_items_lead_employee ON public.installation_work_items(lead_employee_id);

CREATE INDEX IF NOT EXISTS idx_installation_material_usage_work_item ON public.installation_material_usage(work_item_id);
CREATE INDEX IF NOT EXISTS idx_installation_material_usage_material_name ON public.installation_material_usage(material_name);

CREATE INDEX IF NOT EXISTS idx_installation_work_activities_work_item ON public.installation_work_activities(work_item_id);
CREATE INDEX IF NOT EXISTS idx_installation_work_activities_employee ON public.installation_work_activities(employee_id);
CREATE INDEX IF NOT EXISTS idx_installation_work_activities_timestamp ON public.installation_work_activities(timestamp);
CREATE INDEX IF NOT EXISTS idx_installation_work_activities_type ON public.installation_work_activities(activity_type);

-- Create triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_installation_projects_updated_at 
    BEFORE UPDATE ON public.installation_projects 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_installation_work_items_updated_at 
    BEFORE UPDATE ON public.installation_work_items 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_installation_material_usage_updated_at 
    BEFORE UPDATE ON public.installation_material_usage 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Add RLS (Row Level Security) policies
ALTER TABLE public.installation_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.installation_work_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.installation_material_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.installation_work_activities ENABLE ROW LEVEL SECURITY;

-- RLS Policies for installation_projects
CREATE POLICY "Users can view installation projects from their office" ON public.installation_projects
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.customers c 
            JOIN public.users u ON c.office_id = u.office_id 
            WHERE c.id = installation_projects.customer_id 
            AND u.id = auth.uid()
        )
    );

CREATE POLICY "Managers and Directors can insert installation projects" ON public.installation_projects
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('manager', 'director')
        )
    );

CREATE POLICY "Managers and Directors can update installation projects" ON public.installation_projects
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('manager', 'director')
        )
    );

-- RLS Policies for installation_work_items
CREATE POLICY "Users can view work items from their office projects" ON public.installation_work_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.installation_projects ip
            JOIN public.customers c ON ip.customer_id = c.id
            JOIN public.users u ON c.office_id = u.office_id 
            WHERE ip.id = installation_work_items.project_id 
            AND u.id = auth.uid()
        )
    );

CREATE POLICY "Managers and Directors can manage work items" ON public.installation_work_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('manager', 'director')
        )
    );

CREATE POLICY "Employees can update assigned work items" ON public.installation_work_items
    FOR UPDATE USING (
        lead_employee_id = auth.uid() OR 
        team_member_ids::jsonb ? auth.uid()::text
    );

-- RLS Policies for installation_material_usage
CREATE POLICY "Users can view material usage from their office" ON public.installation_material_usage
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.installation_work_items iwi
            JOIN public.installation_projects ip ON iwi.project_id = ip.id
            JOIN public.customers c ON ip.customer_id = c.id
            JOIN public.users u ON c.office_id = u.office_id 
            WHERE iwi.id = installation_material_usage.work_item_id 
            AND u.id = auth.uid()
        )
    );

CREATE POLICY "Employees can record material usage" ON public.installation_material_usage
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.installation_work_items iwi
            WHERE iwi.id = work_item_id 
            AND (iwi.lead_employee_id = auth.uid() OR iwi.team_member_ids::jsonb ? auth.uid()::text)
        )
    );

-- RLS Policies for installation_work_activities
CREATE POLICY "Users can view activities from their office" ON public.installation_work_activities
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.installation_work_items iwi
            JOIN public.installation_projects ip ON iwi.project_id = ip.id
            JOIN public.customers c ON ip.customer_id = c.id
            JOIN public.users u ON c.office_id = u.office_id 
            WHERE iwi.id = installation_work_activities.work_item_id 
            AND u.id = auth.uid()
        )
    );

CREATE POLICY "Employees can insert their own activities" ON public.installation_work_activities
    FOR INSERT WITH CHECK (employee_id = auth.uid());

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON public.installation_projects TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.installation_work_items TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.installation_material_usage TO authenticated;
GRANT SELECT, INSERT ON public.installation_work_activities TO authenticated;

-- Comments for documentation
COMMENT ON TABLE public.installation_projects IS 'Main table for installation projects linked to customers';
COMMENT ON TABLE public.installation_work_items IS 'Individual work items within an installation project';
COMMENT ON TABLE public.installation_material_usage IS 'Material usage tracking for work items';
COMMENT ON TABLE public.installation_work_activities IS 'Activity log for employees working on installation items';

COMMENT ON COLUMN public.installation_work_items.team_member_ids IS 'JSON array of user IDs assigned to this work item';
COMMENT ON COLUMN public.installation_work_items.required_materials IS 'JSON object with material requirements';
COMMENT ON COLUMN public.installation_work_activities.metadata IS 'JSON object for additional activity data';
