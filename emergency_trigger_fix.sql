-- Emergency fix for material allocation trigger conflict
-- Can be run directly in Supabase SQL Editor

-- Temporarily disable the problematic triggers
DROP TRIGGER IF EXISTS trigger_track_material_allocation_changes ON customers;
DROP TRIGGER IF EXISTS trigger_process_confirmed_allocation ON customers;

-- Create a simplified tracking function that handles NULL users gracefully
CREATE OR REPLACE FUNCTION track_material_allocation_workflow()
RETURNS TRIGGER AS $$
DECLARE
    user_role TEXT;
    action_notes TEXT;
    user_name TEXT;
    user_id UUID;
BEGIN
    -- Get the user ID that's being used for this operation
    user_id := COALESCE(NEW.material_allocated_by_id, NEW.material_planned_by_id, NEW.material_confirmed_by_id);
    
    -- Only proceed if we have a valid user ID
    IF user_id IS NOT NULL THEN
        -- Get user role and name
        SELECT role, full_name INTO user_role, user_name 
        FROM users 
        WHERE id = user_id;
        
        -- If user not found, set defaults
        IF user_role IS NULL THEN
            user_role := 'unknown';
            user_name := 'Unknown User';
        END IF;
    ELSE
        -- No user ID available, set defaults
        user_role := 'system';
        user_name := 'System';
    END IF;
    
    -- Validate permission based on role and status change (only if we have a real user)
    IF NEW.material_allocation_status IS DISTINCT FROM OLD.material_allocation_status THEN
        
        -- Only check permissions for known users, allow system operations
        IF user_role != 'system' AND user_role != 'unknown' THEN
            IF NOT check_material_allocation_permission(user_role, OLD.material_allocation_status, NEW.material_allocation_status) THEN
                RAISE EXCEPTION 'User with role % does not have permission to change status from % to %', 
                    user_role, OLD.material_allocation_status, NEW.material_allocation_status;
            END IF;
        END IF;
        
        -- Create action notes based on status transition
        CASE NEW.material_allocation_status
            WHEN 'planned' THEN
                action_notes := format('Plan saved as draft by %s (%s)', user_name, user_role);
            WHEN 'allocated' THEN
                action_notes := format('Materials allocated by %s (%s)', user_name, user_role);
            WHEN 'confirmed' THEN
                action_notes := format('Allocation confirmed by %s (%s) - stock updated', user_name, user_role);
            ELSE
                action_notes := format('Status changed to %s by %s (%s)', NEW.material_allocation_status, user_name, user_role);
        END CASE;

        -- Log the action in history (only if we have a valid user)
        IF user_id IS NOT NULL THEN
            PERFORM log_material_allocation_action(
                NEW.id,
                NEW.material_allocation_status,
                user_id,
                action_notes
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the tracking trigger as AFTER UPDATE to prevent tuple conflicts
CREATE TRIGGER trigger_track_material_allocation_changes
    AFTER UPDATE ON customers
    FOR EACH ROW
    WHEN (NEW.material_allocation_status IS DISTINCT FROM OLD.material_allocation_status)
    EXECUTE FUNCTION track_material_allocation_workflow();

-- Recreate the stock deduction trigger (keep existing function)
CREATE TRIGGER trigger_process_confirmed_allocation
    AFTER UPDATE ON customers
    FOR EACH ROW
    WHEN (NEW.material_allocation_status = 'confirmed' AND OLD.material_allocation_status != 'confirmed')
    EXECUTE FUNCTION process_confirmed_material_allocation();
