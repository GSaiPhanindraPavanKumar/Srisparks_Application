-- Enhanced Material Allocation Audit Trail
-- Run this to add comprehensive tracking of who did what and when

-- Add additional columns for complete audit trail
ALTER TABLE customers ADD COLUMN IF NOT EXISTS material_planned_by_id UUID REFERENCES users(id);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS material_planned_date TIMESTAMPTZ;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS material_confirmed_by_id UUID REFERENCES users(id);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS material_confirmed_date TIMESTAMPTZ;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS material_delivered_by_id UUID REFERENCES users(id);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS material_allocation_history JSONB DEFAULT '[]';

-- Add indexes for the new columns
CREATE INDEX IF NOT EXISTS idx_customers_material_planned_by_id ON customers(material_planned_by_id);
CREATE INDEX IF NOT EXISTS idx_customers_material_confirmed_by_id ON customers(material_confirmed_by_id);
CREATE INDEX IF NOT EXISTS idx_customers_material_delivered_by_id ON customers(material_delivered_by_id);

-- Create function to log allocation history
CREATE OR REPLACE FUNCTION log_material_allocation_action(
    customer_id UUID,
    action_type TEXT,
    user_id UUID,
    notes TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    history_entry JSONB;
    current_history JSONB;
    user_name TEXT;
BEGIN
    -- Get user name
    SELECT full_name INTO user_name FROM users WHERE id = user_id;
    
    -- Create history entry
    history_entry := jsonb_build_object(
        'action', action_type,
        'user_id', user_id,
        'user_name', COALESCE(user_name, 'Unknown User'),
        'timestamp', NOW(),
        'notes', notes
    );
    
    -- Get current history
    SELECT COALESCE(material_allocation_history, '[]'::jsonb) 
    INTO current_history 
    FROM customers 
    WHERE id = customer_id;
    
    -- Append new entry
    UPDATE customers 
    SET material_allocation_history = current_history || history_entry::jsonb
    WHERE id = customer_id;
END;
$$ LANGUAGE plpgsql;

-- Enhanced function to track all allocation status changes
CREATE OR REPLACE FUNCTION track_material_allocation_changes()
RETURNS TRIGGER AS $$
DECLARE
    action_notes TEXT;
BEGIN
    -- Track status changes with proper user attribution
    IF NEW.material_allocation_status IS DISTINCT FROM OLD.material_allocation_status THEN
        
        CASE NEW.material_allocation_status
            WHEN 'planned' THEN
                -- Update planned fields
                NEW.material_planned_by_id := NEW.material_allocated_by_id;
                NEW.material_planned_date := NOW();
                action_notes := 'Material allocation plan created/updated';
                
            WHEN 'allocated' THEN
                -- Update confirmed fields
                NEW.material_confirmed_by_id := NEW.material_allocated_by_id;
                NEW.material_confirmed_date := NOW();
                NEW.material_allocation_date := NOW(); -- Keep existing field for compatibility
                action_notes := 'Material allocation confirmed - stock deducted';
                
            WHEN 'delivered' THEN
                -- Update delivered fields
                NEW.material_delivered_by_id := NEW.material_allocated_by_id;
                NEW.material_delivery_date := NOW();
                action_notes := 'Materials marked as delivered to customer';
                
        END CASE;
        
        -- Log the action in history
        PERFORM log_material_allocation_action(
            NEW.id,
            NEW.material_allocation_status,
            NEW.material_allocated_by_id,
            action_notes
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for tracking changes
DROP TRIGGER IF EXISTS trigger_track_material_allocation_changes ON customers;
CREATE TRIGGER trigger_track_material_allocation_changes
    BEFORE UPDATE ON customers
    FOR EACH ROW
    WHEN (NEW.material_allocation_status IS DISTINCT FROM OLD.material_allocation_status)
    EXECUTE FUNCTION track_material_allocation_changes();

-- Create comprehensive audit view
CREATE OR REPLACE VIEW material_allocation_audit AS
SELECT 
    c.id as customer_id,
    c.name as customer_name,
    c.current_phase,
    c.material_allocation_status,
    
    -- Planning details
    c.material_planned_date,
    up.full_name as planned_by_name,
    up.email as planned_by_email,
    
    -- Confirmation details  
    c.material_confirmed_date,
    uc.full_name as confirmed_by_name,
    uc.email as confirmed_by_email,
    
    -- Delivery details
    c.material_delivery_date,
    ud.full_name as delivered_by_name,
    ud.email as delivered_by_email,
    
    -- Plan details
    c.material_allocation_plan,
    c.material_allocation_notes,
    
    -- Complete history
    c.material_allocation_history,
    
    -- Timing calculations
    CASE 
        WHEN c.material_confirmed_date IS NOT NULL AND c.material_planned_date IS NOT NULL 
        THEN EXTRACT(EPOCH FROM (c.material_confirmed_date - c.material_planned_date)) / 3600 
    END as hours_to_confirm,
    
    CASE 
        WHEN c.material_delivery_date IS NOT NULL AND c.material_confirmed_date IS NOT NULL 
        THEN EXTRACT(EPOCH FROM (c.material_delivery_date - c.material_confirmed_date)) / 3600 
    END as hours_to_deliver
    
FROM customers c
LEFT JOIN users up ON c.material_planned_by_id = up.id
LEFT JOIN users uc ON c.material_confirmed_by_id = uc.id  
LEFT JOIN users ud ON c.material_delivered_by_id = ud.id
WHERE c.material_allocation_status IS NOT NULL
ORDER BY c.material_planned_date DESC NULLS LAST;

-- Summary report view
CREATE OR REPLACE VIEW material_allocation_summary AS
SELECT 
    DATE_TRUNC('day', material_planned_date) as date,
    COUNT(*) as total_plans,
    COUNT(material_confirmed_date) as confirmed_count,
    COUNT(material_delivery_date) as delivered_count,
    AVG(EXTRACT(EPOCH FROM (material_confirmed_date - material_planned_date)) / 3600) as avg_hours_to_confirm,
    AVG(EXTRACT(EPOCH FROM (material_delivery_date - material_confirmed_date)) / 3600) as avg_hours_to_deliver
FROM customers
WHERE material_planned_date IS NOT NULL
GROUP BY DATE_TRUNC('day', material_planned_date)
ORDER BY date DESC;

-- Test the enhanced tracking
DO $$
BEGIN
    RAISE NOTICE 'Enhanced Material Allocation Audit Trail Setup Complete!';
    RAISE NOTICE '';
    RAISE NOTICE 'New Tracking Columns Added:';
    RAISE NOTICE '• material_planned_by_id & material_planned_date';
    RAISE NOTICE '• material_confirmed_by_id & material_confirmed_date';  
    RAISE NOTICE '• material_delivered_by_id & material_delivery_date';
    RAISE NOTICE '• material_allocation_history (complete JSON log)';
    RAISE NOTICE '';
    RAISE NOTICE 'New Views Created:';
    RAISE NOTICE '• material_allocation_audit (detailed audit trail)';
    RAISE NOTICE '• material_allocation_summary (performance metrics)';
    RAISE NOTICE '';
    RAISE NOTICE 'Enhanced triggers now track complete workflow!';
END $$;
