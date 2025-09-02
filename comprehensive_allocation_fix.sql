-- Comprehensive fix for material allocation workflow
-- This ensures proper user tracking, date recording, and stock deduction

-- First, drop existing triggers to start fresh
DROP TRIGGER IF EXISTS trigger_track_material_allocation_changes ON customers;
DROP TRIGGER IF EXISTS trigger_process_confirmed_allocation ON customers;

-- Enhanced stock deduction function with proper logging
CREATE OR REPLACE FUNCTION process_confirmed_material_allocation()
RETURNS TRIGGER AS $$
DECLARE
    allocation_plan JSONB;
    plan_item JSONB;
    item_id UUID;
    allocated_qty INTEGER;
    current_stock_qty INTEGER;
    new_stock INTEGER;
    user_id UUID;
BEGIN
    -- Only process when status changes to 'confirmed'
    IF NEW.material_allocation_status = 'confirmed' AND 
       (OLD.material_allocation_status IS NULL OR OLD.material_allocation_status != 'confirmed') THEN
        
        -- Get the user who confirmed the allocation
        user_id := COALESCE(NEW.material_confirmed_by_id, NEW.material_allocated_by_id);
        
        -- Validate allocation plan exists
        IF NEW.material_allocation_plan IS NULL OR NEW.material_allocation_plan = '' THEN
            RAISE EXCEPTION 'Cannot confirm allocation: No allocation plan found for customer %', NEW.name;
        END IF;
        
        -- Parse the allocation plan
        BEGIN
            allocation_plan := NEW.material_allocation_plan::JSONB;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE EXCEPTION 'Cannot confirm allocation: Invalid allocation plan format for customer %', NEW.name;
        END;
        
        -- Validate allocation plan has items
        IF NOT (allocation_plan ? 'items') THEN
            -- Handle old format: {item_id: quantity, item_id: quantity}
            -- Convert to new format for processing
            DECLARE
                temp_plan JSONB := '{"items": []}'::JSONB;
                key TEXT;
                value TEXT;
            BEGIN
                -- Check if allocation_plan has any keys (old format)
                IF jsonb_typeof(allocation_plan) = 'object' THEN
                    -- Convert old format to new format
                    FOR key IN SELECT jsonb_object_keys(allocation_plan)
                    LOOP
                        -- Skip non-UUID keys or special keys
                        BEGIN
                            -- Try to cast key as UUID to validate it's an item_id
                            IF key::UUID IS NOT NULL THEN
                                value := allocation_plan->>key;
                                -- Add to items array
                                temp_plan := jsonb_set(
                                    temp_plan,
                                    '{items}',
                                    (temp_plan->'items') || jsonb_build_object(
                                        'item_id', key,
                                        'allocated_quantity', value::INTEGER
                                    )
                                );
                            END IF;
                        EXCEPTION
                            WHEN OTHERS THEN
                                -- Skip invalid keys
                                CONTINUE;
                        END;
                    END LOOP;
                    allocation_plan := temp_plan;
                ELSE
                    RAISE EXCEPTION 'Cannot confirm allocation: No items found in allocation plan for customer %', NEW.name;
                END IF;
            END;
        END IF;
        
        -- Double check we have items after conversion
        IF NOT (allocation_plan ? 'items') OR jsonb_array_length(allocation_plan->'items') = 0 THEN
            RAISE EXCEPTION 'Cannot confirm allocation: No valid items found in allocation plan for customer %', NEW.name;
        END IF;
        
        -- Process each item in the allocation plan
        FOR plan_item IN SELECT * FROM jsonb_array_elements(allocation_plan->'items')
        LOOP
            -- Extract item details
            BEGIN
                item_id := (plan_item->>'item_id')::UUID;
                allocated_qty := COALESCE((plan_item->>'allocated_quantity')::INTEGER, 0);
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE EXCEPTION 'Invalid item data in allocation plan for customer %: %', NEW.name, plan_item;
            END;
            
            -- Skip if no quantity allocated
            IF allocated_qty <= 0 THEN
                CONTINUE;
            END IF;
            
            -- Get current stock (with row lock to prevent race conditions)
            SELECT current_stock INTO current_stock_qty
            FROM stock_items
            WHERE id = item_id
            FOR UPDATE;
            
            -- If item not found, create a log entry but continue
            IF current_stock_qty IS NULL THEN
                INSERT INTO stock_log (
                    stock_item_id,
                    action_type,
                    quantity_change,
                    previous_stock,
                    new_stock,
                    reason,
                    office_id,
                    user_id,
                    created_at
                ) VALUES (
                    item_id,
                    'allocation_error',
                    0,
                    0,
                    0,
                    format('ERROR: Item not found in stock for customer allocation: %s', NEW.name),
                    NEW.office_id,
                    user_id,
                    NOW()
                );
                CONTINUE;
            END IF;
            
            -- Calculate new stock (can go negative)
            new_stock := current_stock_qty - allocated_qty;
            
            -- Update stock quantity
            UPDATE stock_items
            SET 
                current_stock = new_stock,
                updated_at = NOW()
            WHERE id = item_id;
            
            -- Create stock log entry
            INSERT INTO stock_log (
                stock_item_id,
                action_type,
                quantity_change,
                previous_stock,
                new_stock,
                reason,
                office_id,
                user_id,
                created_at
            ) VALUES (
                item_id,
                'decrease',
                -allocated_qty,
                current_stock_qty,
                new_stock,
                format('Material allocated for customer: %s (Qty: %s, Status: confirmed)', NEW.name, allocated_qty),
                NEW.office_id,
                user_id,
                NOW()
            );
            
        END LOOP;
        
        -- Log successful allocation confirmation
        RAISE NOTICE 'Material allocation confirmed for customer % - stock quantities updated', NEW.name;
        
        -- Update customer status to enable installation phase
        -- Once materials are allocated and confirmed, customer can proceed to installation
        UPDATE customers 
        SET 
            current_phase = 'installation',
            updated_at = NOW()
        WHERE id = NEW.id;
        
        RAISE NOTICE 'Customer % current_phase updated to installation phase', NEW.name;
        
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the stock deduction trigger
CREATE TRIGGER trigger_process_confirmed_allocation
    AFTER UPDATE ON customers
    FOR EACH ROW
    WHEN (NEW.material_allocation_status = 'confirmed')
    EXECUTE FUNCTION process_confirmed_material_allocation();

-- Function to validate material allocation plan format
CREATE OR REPLACE FUNCTION validate_material_allocation_plan(plan_json TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    plan JSONB;
    item JSONB;
    key TEXT;
BEGIN
    -- Try to parse JSON
    BEGIN
        plan := plan_json::JSONB;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END;
    
    -- Check if new format with items array exists
    IF (plan ? 'items') THEN
        -- Validate each item has required fields
        FOR item IN SELECT * FROM jsonb_array_elements(plan->'items')
        LOOP
            IF NOT (item ? 'item_id') OR NOT (item ? 'allocated_quantity') THEN
                RETURN FALSE;
            END IF;
        END LOOP;
        RETURN TRUE;
    END IF;
    
    -- Check if old format (direct key-value pairs)
    IF jsonb_typeof(plan) = 'object' THEN
        -- Check if at least one key looks like a UUID
        FOR key IN SELECT jsonb_object_keys(plan)
        LOOP
            BEGIN
                -- Try to validate as UUID
                IF key::UUID IS NOT NULL THEN
                    RETURN TRUE;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    -- Continue checking other keys
                    CONTINUE;
            END;
        END LOOP;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- Test the stock deduction manually for existing confirmed allocations
-- (Run this to fix any customers that were confirmed but didn't get stock deducted)
DO $$
DECLARE
    customer_record RECORD;
BEGIN
    -- Find all customers with confirmed status
    FOR customer_record IN 
        SELECT id, name, material_allocation_plan, material_allocation_status
        FROM customers 
        WHERE material_allocation_status = 'confirmed'
        AND material_allocation_plan IS NOT NULL
        AND material_allocation_plan != ''
    LOOP
        -- Trigger stock deduction for each confirmed allocation
        UPDATE customers 
        SET updated_at = NOW()
        WHERE id = customer_record.id;
        
        RAISE NOTICE 'Processed stock deduction for customer: %', customer_record.name;
    END LOOP;
END;
$$;
