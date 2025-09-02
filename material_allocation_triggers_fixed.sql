-- Fix for PostgreSQL trigger conflict: "tuple to be updated was already modified by an operation triggered by the current command"
-- The issue was that the BEFORE trigger was modifying fields that the application was also trying to update

-- Drop existing triggers to recreate them
DROP TRIGGER IF EXISTS trigger_track_material_allocation_changes ON customers;
DROP TRIGGER IF EXISTS trigger_process_confirmed_allocation ON customers;

-- Update the workflow tracking function to only handle validation and logging
-- Remove field modifications to avoid tuple conflicts
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
        
        -- Create action notes based on status transition
        CASE NEW.material_allocation_status
            WHEN 'planned' THEN
                action_notes := format('Plan saved as draft by %s (%s)', user_name, user_role);

            WHEN 'allocated' THEN
                action_notes := format('Materials allocated by %s (%s)', user_name, user_role);

            WHEN 'confirmed' THEN
                action_notes := format('Allocation confirmed by %s (%s) - stock updated', user_name, user_role);

        END CASE;

        -- Log the action in history (but don't modify the record)
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

-- Create the workflow tracking trigger as AFTER UPDATE instead of BEFORE
-- This prevents tuple modification conflicts
CREATE TRIGGER trigger_track_material_allocation_changes
    AFTER UPDATE ON customers
    FOR EACH ROW
    WHEN (NEW.material_allocation_status IS DISTINCT FROM OLD.material_allocation_status)
    EXECUTE FUNCTION track_material_allocation_workflow();

-- Stock deduction trigger - keep as AFTER UPDATE
CREATE TRIGGER trigger_process_confirmed_allocation
    AFTER UPDATE ON customers
    FOR EACH ROW
    WHEN (NEW.material_allocation_status = 'confirmed' AND OLD.material_allocation_status != 'confirmed')
    EXECUTE FUNCTION process_confirmed_material_allocation();

-- Note: The application layer (SimplifiedMaterialAllocationService) should now handle
-- setting these fields directly instead of relying on the trigger:
-- - material_planned_by_id and material_planned_date (for 'planned' status)
-- - material_confirmed_by_id and material_confirmed_date (for 'allocated' status) 
-- - material_allocation_date (for 'confirmed' status)
