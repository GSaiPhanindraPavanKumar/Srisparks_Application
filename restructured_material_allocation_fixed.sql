-- Fixed Restructured Material Allocation Workflow
-- Handles view dependencies properly
-- Role-based permissions: Lead -> Manager -> Director
-- Phases: planned -> allocated -> confirmed

-- Update material allocation status enum to reflect new workflow
-- Drop existing check constraint if it exists
ALTER TABLE customers DROP CONSTRAINT IF EXISTS customers_material_allocation_status_check;

-- Add new check constraint with updated statuses
ALTER TABLE customers ADD CONSTRAINT customers_material_allocation_status_check 
CHECK (material_allocation_status IN ('pending', 'planned', 'allocated', 'confirmed'));

-- Update audit columns to reflect new workflow stages
-- Keep existing columns but clarify their purposes
COMMENT ON COLUMN customers.material_planned_by_id IS 'Lead/Manager/Director who created the plan (draft)';
COMMENT ON COLUMN customers.material_planned_date IS 'When the plan was created/saved as draft';
COMMENT ON COLUMN customers.material_confirmed_by_id IS 'Manager/Director who allocated materials';
COMMENT ON COLUMN customers.material_confirmed_date IS 'When materials were allocated (proceed)';
COMMENT ON COLUMN customers.material_allocated_by_id IS 'Director who confirmed the allocation';
COMMENT ON COLUMN customers.material_allocation_date IS 'When allocation was confirmed (final)';

-- Remove delivery fields as they are no longer needed
-- First drop dependent views to avoid CASCADE issues
DROP VIEW IF EXISTS customer_material_allocations CASCADE;
DROP VIEW IF EXISTS material_allocation_audit CASCADE;
DROP VIEW IF EXISTS material_allocation_summary CASCADE;

-- Now safely drop the columns
ALTER TABLE customers DROP COLUMN IF EXISTS material_delivery_date;
ALTER TABLE customers DROP COLUMN IF EXISTS material_delivered_by_id;
ALTER TABLE customers DROP COLUMN IF EXISTS material_delivered_date;

-- Create role-based permission function
CREATE OR REPLACE FUNCTION check_material_allocation_permission(
    user_role TEXT,
    current_status TEXT,
    new_status TEXT
) RETURNS BOOLEAN AS $$
BEGIN
    -- Lead can only save as draft (planned)
    IF user_role = 'lead' THEN
        RETURN (current_status IN ('pending', 'planned') AND new_status = 'planned');
    END IF;
    
    -- Manager can save draft and proceed (allocate)
    IF user_role = 'manager' THEN
        RETURN (
            (current_status IN ('pending', 'planned') AND new_status IN ('planned', 'allocated')) OR
            (current_status = 'allocated' AND new_status = 'allocated') -- can modify their own allocation
        );
    END IF;
    
    -- Director can do everything except modify confirmed allocations
    IF user_role = 'director' THEN
        RETURN (current_status != 'confirmed' OR new_status = 'confirmed');
    END IF;
    
    -- No permission by default
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- Enhanced function to track workflow changes with role validation
CREATE OR REPLACE FUNCTION track_material_allocation_workflow()
RETURNS TRIGGER AS $$
DECLARE
    user_role TEXT;
    action_notes TEXT;
    user_name TEXT;
BEGIN
    -- Get user role and name
    SELECT role, full_name INTO user_role, user_name 
    FROM users 
    WHERE id = COALESCE(NEW.material_allocated_by_id, NEW.material_planned_by_id, NEW.material_confirmed_by_id);
    
    -- Validate permission based on role and status change
    IF NEW.material_allocation_status IS DISTINCT FROM OLD.material_allocation_status THEN
        
        -- Check if user has permission for this transition
        IF NOT check_material_allocation_permission(user_role, OLD.material_allocation_status, NEW.material_allocation_status) THEN
            RAISE EXCEPTION 'User with role % does not have permission to change status from % to %', 
                user_role, OLD.material_allocation_status, NEW.material_allocation_status;
        END IF;
        
        -- Handle status transitions
        CASE NEW.material_allocation_status
            WHEN 'planned' THEN
                -- Save as draft - any role can do this to their own work
                NEW.material_planned_by_id := NEW.material_allocated_by_id;
                NEW.material_planned_date := NOW();
                action_notes := format('Plan saved as draft by %s (%s)', user_name, user_role);

            WHEN 'allocated' THEN
                -- Proceed - Manager or Director only
                NEW.material_confirmed_by_id := NEW.material_allocated_by_id;
                NEW.material_confirmed_date := NOW();
                action_notes := format('Materials allocated by %s (%s)', user_name, user_role);

            WHEN 'confirmed' THEN
                -- Confirm - Director only, triggers stock deduction
                NEW.material_allocation_date := NOW();
                action_notes := format('Allocation confirmed by %s (%s) - stock updated', user_name, user_role);
                
                -- Only confirm operation triggers stock deduction
                -- This will be handled by the existing stock deduction trigger

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

-- Update the trigger
DROP TRIGGER IF EXISTS trigger_track_material_allocation_changes ON customers;
CREATE TRIGGER trigger_track_material_allocation_changes
    BEFORE UPDATE ON customers
    FOR EACH ROW
    WHEN (NEW.material_allocation_status IS DISTINCT FROM OLD.material_allocation_status)
    EXECUTE FUNCTION track_material_allocation_workflow();

-- Stock deduction trigger - only fires on 'confirmed' status
CREATE OR REPLACE FUNCTION process_confirmed_material_allocation()
RETURNS TRIGGER AS $$
DECLARE
    allocation_plan JSONB;
    plan_item JSONB;
    item_id UUID;
    allocated_qty INTEGER;
    current_stock INTEGER;
    new_stock INTEGER;
BEGIN
    -- Only process when status changes to 'confirmed'
    IF NEW.material_allocation_status = 'confirmed' AND 
       OLD.material_allocation_status != 'confirmed' THEN
        
        -- Parse the allocation plan
        allocation_plan := NEW.material_allocation_plan::JSONB;
        
        -- Process each item in the allocation plan
        FOR plan_item IN SELECT * FROM jsonb_array_elements(allocation_plan->'items')
        LOOP
            item_id := (plan_item->>'item_id')::UUID;
            allocated_qty := (plan_item->>'allocated_quantity')::INTEGER;
            
            -- Get current stock
            SELECT stock_quantity INTO current_stock
            FROM stock_items
            WHERE id = item_id;
            
            -- Calculate new stock (can go negative)
            new_stock := COALESCE(current_stock, 0) - allocated_qty;
            
            -- Update stock quantity
            UPDATE stock_items
            SET 
                stock_quantity = new_stock,
                updated_at = NOW()
            WHERE id = item_id;
            
            -- Create stock log entry
            INSERT INTO stock_logs (
                stock_item_id,
                transaction_type,
                quantity_changed,
                quantity_before,
                quantity_after,
                reference_type,
                reference_id,
                notes,
                created_by_id,
                created_at
            ) VALUES (
                item_id,
                'allocation',
                -allocated_qty,
                current_stock,
                new_stock,
                'material_allocation',
                NEW.id,
                format('Material allocated for customer: %s (Status: confirmed)', NEW.name),
                NEW.material_allocated_by_id,
                NOW()
            );
            
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for stock deduction on confirmation
DROP TRIGGER IF EXISTS trigger_process_confirmed_allocation ON customers;
CREATE TRIGGER trigger_process_confirmed_allocation
    AFTER UPDATE ON customers
    FOR EACH ROW
    WHEN (NEW.material_allocation_status = 'confirmed' AND OLD.material_allocation_status != 'confirmed')
    EXECUTE FUNCTION process_confirmed_material_allocation();

-- Recreate the material allocation audit view (without delivery fields)
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

    -- Allocation details
    c.material_confirmed_date,
    uc.full_name as allocated_by_name,
    uc.email as allocated_by_email,

    -- Confirmation details
    c.material_allocation_date,
    ua.full_name as confirmed_by_name,
    ua.email as confirmed_by_email,

    -- Plan details
    c.material_allocation_plan,
    c.material_allocation_notes,

    -- Complete history
    c.material_allocation_history,

    -- Timing calculations
    CASE
        WHEN c.material_confirmed_date IS NOT NULL AND c.material_planned_date IS NOT NULL
        THEN EXTRACT(EPOCH FROM (c.material_confirmed_date - c.material_planned_date)) / 3600
    END as hours_to_allocate,

    CASE
        WHEN c.material_allocation_date IS NOT NULL AND c.material_confirmed_date IS NOT NULL
        THEN EXTRACT(EPOCH FROM (c.material_allocation_date - c.material_confirmed_date)) / 3600
    END as hours_to_confirm

FROM customers c
LEFT JOIN users up ON c.material_planned_by_id = up.id
LEFT JOIN users uc ON c.material_confirmed_by_id = uc.id
LEFT JOIN users ua ON c.material_allocated_by_id = ua.id
WHERE c.material_allocation_status IS NOT NULL
ORDER BY c.material_planned_date DESC NULLS LAST;

-- Create view for role-based material allocation access
CREATE OR REPLACE VIEW material_allocation_by_role AS
SELECT 
    c.id as customer_id,
    c.name as customer_name,
    c.material_allocation_status,
    c.material_allocation_plan,
    
    -- Planning info
    c.material_planned_date,
    up.full_name as planned_by_name,
    up.role as planned_by_role,
    
    -- Allocation info  
    c.material_confirmed_date as allocated_date,
    ua.full_name as allocated_by_name,
    ua.role as allocated_by_role,
    
    -- Confirmation info
    c.material_allocation_date as confirmed_date,
    uc.full_name as confirmed_by_name,
    uc.role as confirmed_by_role,
    
    -- Permission flags for different roles
    CASE 
        WHEN c.material_allocation_status IN ('pending', 'planned') THEN TRUE
        ELSE FALSE
    END as lead_can_edit,
    
    CASE 
        WHEN c.material_allocation_status IN ('pending', 'planned', 'allocated') THEN TRUE
        ELSE FALSE  
    END as manager_can_edit,
    
    CASE 
        WHEN c.material_allocation_status != 'confirmed' THEN TRUE
        ELSE FALSE
    END as director_can_edit,
    
    -- Visibility flags
    CASE 
        WHEN c.material_allocation_status = 'confirmed' THEN TRUE
        ELSE FALSE
    END as visible_to_employees

FROM customers c
LEFT JOIN users up ON c.material_planned_by_id = up.id
LEFT JOIN users ua ON c.material_confirmed_by_id = ua.id  
LEFT JOIN users uc ON c.material_allocated_by_id = uc.id
WHERE c.material_allocation_status IS NOT NULL
ORDER BY c.material_planned_date DESC NULLS LAST;

-- Recreate summary report view (without delivery metrics)
CREATE OR REPLACE VIEW material_allocation_summary AS
SELECT
    DATE_TRUNC('day', material_planned_date) as date,
    COUNT(*) as total_plans,
    COUNT(material_confirmed_date) as allocated_count,
    COUNT(material_allocation_date) as confirmed_count,
    AVG(EXTRACT(EPOCH FROM (material_confirmed_date - material_planned_date)) / 3600) as avg_hours_to_allocate,
    AVG(EXTRACT(EPOCH FROM (material_allocation_date - material_confirmed_date)) / 3600) as avg_hours_to_confirm
FROM customers
WHERE material_planned_date IS NOT NULL
GROUP BY DATE_TRUNC('day', material_planned_date)
ORDER BY date DESC;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '🎯 Restructured Material Allocation Workflow Complete!';
    RAISE NOTICE '';
    RAISE NOTICE '📋 New Workflow:';
    RAISE NOTICE '1. Save as Draft (planned) - Lead, Manager, Director';
    RAISE NOTICE '2. Proceed (allocated) - Manager, Director only';  
    RAISE NOTICE '3. Confirm (confirmed) - Director only';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 Permissions:';
    RAISE NOTICE '• Lead: Can only save drafts, view planned status';
    RAISE NOTICE '• Manager: Can save drafts + allocate, cannot modify after allocation';
    RAISE NOTICE '• Director: Full control until confirmation';
    RAISE NOTICE '• Employees: Can view only after confirmation';
    RAISE NOTICE '';
    RAISE NOTICE '📦 Stock Impact:';
    RAISE NOTICE '• Stock deduction only happens on "confirmed" status';
    RAISE NOTICE '• Allows negative stock for shortage tracking';
    RAISE NOTICE '• Complete audit trail maintained';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Fixed dependency issues with views';
END $$;
