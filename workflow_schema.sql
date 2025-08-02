-- Customer Status History Table
CREATE TABLE customer_status_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN (
        'application', 'loanApproval', 'installationAssigned', 
        'material', 'installation', 'documentation', 
        'meter', 'inverterTurnOn', 'completed'
    )),
    status_date TIMESTAMP WITH TIME ZONE NOT NULL,
    assigned_user_id UUID REFERENCES users(id),
    notes TEXT,
    documents TEXT[], -- Array of document URLs/paths
    metadata JSONB, -- Additional flexible data
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Work Assignments Table
CREATE TABLE work_assignments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    work_id UUID DEFAULT gen_random_uuid(), -- For grouping related assignments
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    work_stage TEXT NOT NULL CHECK (work_stage IN (
        'application', 'loanApproval', 'installationAssigned', 
        'material', 'installation', 'documentation', 
        'meter', 'inverterTurnOn', 'completed'
    )),
    assigned_user_ids UUID[] NOT NULL, -- Array of user IDs
    assigned_user_names TEXT[] NOT NULL, -- Array of user names for quick access
    location TEXT NOT NULL CHECK (location IN ('office', 'customerSite', 'external')),
    customer_address TEXT,
    location_notes TEXT,
    scheduled_date TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    components_used JSONB DEFAULT '[]'::jsonb, -- Array of component usage
    notes TEXT,
    attachments TEXT[], -- Array of file URLs
    is_completed BOOLEAN DEFAULT FALSE,
    office_id UUID NOT NULL REFERENCES offices(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Inventory Components Table
CREATE TABLE inventory_components (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL, -- e.g., 'solar_panels', 'inverters', 'batteries', 'cables', etc.
    unit TEXT NOT NULL, -- e.g., 'pieces', 'meters', 'kg'
    current_stock INTEGER NOT NULL DEFAULT 0,
    minimum_stock INTEGER NOT NULL DEFAULT 0,
    unit_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    supplier TEXT,
    supplier_contact TEXT,
    office_id UUID NOT NULL REFERENCES offices(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Stock Usage Log Table
CREATE TABLE stock_usage_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    component_id UUID NOT NULL REFERENCES inventory_components(id),
    work_assignment_id UUID REFERENCES work_assignments(id),
    quantity_used INTEGER NOT NULL,
    stock_before INTEGER NOT NULL,
    stock_after INTEGER NOT NULL,
    used_by UUID REFERENCES users(id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Customer Complaints Table
CREATE TABLE customer_complaints (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('technical', 'maintenance', 'warranty', 'billing', 'other')),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    service_type TEXT NOT NULL CHECK (service_type IN ('freeService', 'paidService', 'warranty')),
    is_under_warranty BOOLEAN NOT NULL DEFAULT FALSE,
    installation_date TIMESTAMP WITH TIME ZONE,
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    assigned_user_ids UUID[] NOT NULL,
    assigned_user_names TEXT[] NOT NULL,
    scheduled_date TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution TEXT,
    components_used JSONB, -- Array of component usage for resolution
    service_cost DECIMAL(10,2),
    attachments TEXT[], -- Array of file URLs
    office_id UUID NOT NULL REFERENCES offices(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_customer_status_history_customer_id ON customer_status_history(customer_id);
CREATE INDEX idx_customer_status_history_status ON customer_status_history(status);
CREATE INDEX idx_customer_status_history_status_date ON customer_status_history(status_date);

CREATE INDEX idx_work_assignments_customer_id ON work_assignments(customer_id);
CREATE INDEX idx_work_assignments_work_stage ON work_assignments(work_stage);
CREATE INDEX idx_work_assignments_office_id ON work_assignments(office_id);
CREATE INDEX idx_work_assignments_assigned_user_ids ON work_assignments USING GIN(assigned_user_ids);
CREATE INDEX idx_work_assignments_is_completed ON work_assignments(is_completed);

CREATE INDEX idx_inventory_components_office_id ON inventory_components(office_id);
CREATE INDEX idx_inventory_components_category ON inventory_components(category);
CREATE INDEX idx_inventory_components_is_active ON inventory_components(is_active);

CREATE INDEX idx_stock_usage_log_component_id ON stock_usage_log(component_id);
CREATE INDEX idx_stock_usage_log_work_assignment_id ON stock_usage_log(work_assignment_id);

CREATE INDEX idx_customer_complaints_customer_id ON customer_complaints(customer_id);
CREATE INDEX idx_customer_complaints_status ON customer_complaints(status);
CREATE INDEX idx_customer_complaints_office_id ON customer_complaints(office_id);
CREATE INDEX idx_customer_complaints_assigned_user_ids ON customer_complaints USING GIN(assigned_user_ids);

-- Create RLS policies
ALTER TABLE customer_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_components ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_usage_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_complaints ENABLE ROW LEVEL SECURITY;

-- Customer Status History Policies
CREATE POLICY "Users can view customer status history for their office" ON customer_status_history
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM customers c 
            WHERE c.id = customer_status_history.customer_id 
            AND (
                auth.jwt() ->> 'role' = 'director' OR
                c.office_id = (auth.jwt() ->> 'office_id')::UUID
            )
        )
    );

CREATE POLICY "Users can insert customer status history for their office" ON customer_status_history
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM customers c 
            WHERE c.id = customer_status_history.customer_id 
            AND (
                auth.jwt() ->> 'role' = 'director' OR
                c.office_id = (auth.jwt() ->> 'office_id')::UUID
            )
        )
    );

-- Work Assignments Policies
CREATE POLICY "Users can view work assignments for their office" ON work_assignments
    FOR SELECT USING (
        auth.jwt() ->> 'role' = 'director' OR
        office_id = (auth.jwt() ->> 'office_id')::UUID OR
        (auth.jwt() ->> 'user_id')::UUID = ANY(assigned_user_ids)
    );

CREATE POLICY "Users can manage work assignments for their office" ON work_assignments
    FOR ALL USING (
        auth.jwt() ->> 'role' = 'director' OR
        office_id = (auth.jwt() ->> 'office_id')::UUID
    );

-- Inventory Components Policies
CREATE POLICY "Users can view inventory for their office" ON inventory_components
    FOR SELECT USING (
        auth.jwt() ->> 'role' = 'director' OR
        office_id = (auth.jwt() ->> 'office_id')::UUID
    );

CREATE POLICY "Users can manage inventory for their office" ON inventory_components
    FOR ALL USING (
        auth.jwt() ->> 'role' = 'director' OR
        office_id = (auth.jwt() ->> 'office_id')::UUID
    );

-- Stock Usage Log Policies
CREATE POLICY "Users can view stock usage for their office" ON stock_usage_log
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM inventory_components ic 
            WHERE ic.id = stock_usage_log.component_id 
            AND (
                auth.jwt() ->> 'role' = 'director' OR
                ic.office_id = (auth.jwt() ->> 'office_id')::UUID
            )
        )
    );

CREATE POLICY "Users can log stock usage for their office" ON stock_usage_log
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM inventory_components ic 
            WHERE ic.id = stock_usage_log.component_id 
            AND (
                auth.jwt() ->> 'role' = 'director' OR
                ic.office_id = (auth.jwt() ->> 'office_id')::UUID
            )
        )
    );

-- Customer Complaints Policies
CREATE POLICY "Users can view complaints for their office" ON customer_complaints
    FOR SELECT USING (
        auth.jwt() ->> 'role' = 'director' OR
        office_id = (auth.jwt() ->> 'office_id')::UUID OR
        (auth.jwt() ->> 'user_id')::UUID = ANY(assigned_user_ids)
    );

CREATE POLICY "Users can manage complaints for their office" ON customer_complaints
    FOR ALL USING (
        auth.jwt() ->> 'role' = 'director' OR
        office_id = (auth.jwt() ->> 'office_id')::UUID
    );

-- Create functions for analytics
CREATE OR REPLACE FUNCTION get_customer_status_distribution(office_id UUID)
RETURNS TABLE(status TEXT, count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        csh.status,
        COUNT(*) as count
    FROM customer_status_history csh
    JOIN customers c ON c.id = csh.customer_id
    WHERE (office_id IS NULL OR c.office_id = office_id)
    AND csh.id IN (
        -- Get the latest status for each customer
        SELECT DISTINCT ON (customer_id) id
        FROM customer_status_history
        WHERE customer_id = csh.customer_id
        ORDER BY customer_id, status_date DESC
    )
    GROUP BY csh.status
    ORDER BY csh.status;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_work_assignment_metrics(office_id UUID)
RETURNS TABLE(
    total_assignments BIGINT,
    completed_assignments BIGINT,
    pending_assignments BIGINT,
    overdue_assignments BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_assignments,
        COUNT(*) FILTER (WHERE is_completed = true) as completed_assignments,
        COUNT(*) FILTER (WHERE is_completed = false) as pending_assignments,
        COUNT(*) FILTER (WHERE scheduled_date < NOW() AND is_completed = false) as overdue_assignments
    FROM work_assignments wa
    WHERE (office_id IS NULL OR wa.office_id = office_id);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_complaint_metrics(office_id UUID)
RETURNS TABLE(
    total_complaints BIGINT,
    open_complaints BIGINT,
    resolved_complaints BIGINT,
    free_service_complaints BIGINT,
    paid_service_complaints BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_complaints,
        COUNT(*) FILTER (WHERE status = 'open') as open_complaints,
        COUNT(*) FILTER (WHERE status = 'resolved') as resolved_complaints,
        COUNT(*) FILTER (WHERE service_type = 'freeService') as free_service_complaints,
        COUNT(*) FILTER (WHERE service_type = 'paidService') as paid_service_complaints
    FROM customer_complaints cc
    WHERE (office_id IS NULL OR cc.office_id = office_id);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_inventory_status(office_id UUID)
RETURNS TABLE(
    total_components BIGINT,
    low_stock_components BIGINT,
    out_of_stock_components BIGINT,
    total_value DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_components,
        COUNT(*) FILTER (WHERE current_stock <= minimum_stock) as low_stock_components,
        COUNT(*) FILTER (WHERE current_stock = 0) as out_of_stock_components,
        COALESCE(SUM(current_stock * unit_price), 0) as total_value
    FROM inventory_components ic
    WHERE (office_id IS NULL OR ic.office_id = office_id)
    AND is_active = true;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_customer_status_history_updated_at 
    BEFORE UPDATE ON customer_status_history 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_work_assignments_updated_at 
    BEFORE UPDATE ON work_assignments 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inventory_components_updated_at 
    BEFORE UPDATE ON inventory_components 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customer_complaints_updated_at 
    BEFORE UPDATE ON customer_complaints 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
