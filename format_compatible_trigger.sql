-- Quick fix for allocation plan format issue
-- This handles both old format {item_id: quantity} and new format {items: [...]}

DROP TRIGGER IF EXISTS trigger_process_confirmed_allocation ON customers;

-- Fixed stock deduction function that handles multiple allocation plan formats
CREATE OR REPLACE FUNCTION process_confirmed_material_allocation()
RETURNS TRIGGER AS $$
DECLARE
    allocation_plan JSONB;
    plan_item JSONB;
    item_id UUID;
    allocated_qty INTEGER;
    current_stock INTEGER;
    new_stock INTEGER;
    user_id UUID;
    key TEXT;
    temp_plan JSONB;
BEGIN
    -- Only process when status changes to 'confirmed'
    IF NEW.material_allocation_status = 'confirmed' AND 
       (OLD.material_allocation_status IS NULL OR OLD.material_allocation_status != 'confirmed') THEN
        
        -- Get the user who confirmed the allocation
        user_id := COALESCE(NEW.material_confirmed_by_id, NEW.material_allocated_by_id);
        
        -- Validate allocation plan exists
        IF NEW.material_allocation_plan IS NULL OR NEW.material_allocation_plan = '' THEN
            RAISE NOTICE 'No allocation plan found for customer %, skipping stock deduction', NEW.name;
            RETURN NEW;
        END IF;
        
        -- Parse the allocation plan
        BEGIN
            allocation_plan := NEW.material_allocation_plan::JSONB;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Invalid allocation plan format for customer %, skipping stock deduction', NEW.name;
                RETURN NEW;
        END;
        
        -- Handle different allocation plan formats
        IF NOT (allocation_plan ? 'items') THEN
            -- Old format: {item_id: quantity, item_id: quantity}
            -- Convert to new format for processing
            temp_plan := '{"items": []}'::JSONB;
            
            -- Check if allocation_plan has any keys
            IF jsonb_typeof(allocation_plan) = 'object' THEN
                FOR key IN SELECT jsonb_object_keys(allocation_plan)
                LOOP
                    -- Skip non-UUID keys or special keys
                    BEGIN
                        -- Try to cast key as UUID to validate it's an item_id
                        IF key::UUID IS NOT NULL AND (allocation_plan->>key)::INTEGER > 0 THEN
                            -- Add to items array
                            temp_plan := jsonb_set(
                                temp_plan,
                                '{items}',
                                (temp_plan->'items') || jsonb_build_object(
                                    'item_id', key,
                                    'allocated_quantity', (allocation_plan->>key)::INTEGER
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
            END IF;
        END IF;
        
        -- Check if we have items to process
        IF NOT (allocation_plan ? 'items') OR jsonb_array_length(allocation_plan->'items') = 0 THEN
            RAISE NOTICE 'No valid items found in allocation plan for customer %, skipping stock deduction', NEW.name;
            RETURN NEW;
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
                    RAISE NOTICE 'Invalid item data in allocation plan for customer %: %, skipping item', NEW.name, plan_item;
                    CONTINUE;
            END;
            
            -- Skip if no quantity allocated
            IF allocated_qty <= 0 THEN
                CONTINUE;
            END IF;
            
            -- Get current stock
            SELECT stock_quantity INTO current_stock
            FROM stock_items
            WHERE id = item_id;
            
            -- If item not found, create a log entry but continue
            IF current_stock IS NULL THEN
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
                    'allocation_error',
                    0,
                    0,
                    0,
                    'material_allocation',
                    NEW.id,
                    format('ERROR: Item not found in stock for customer allocation: %s', NEW.name),
                    user_id,
                    NOW()
                );
                CONTINUE;
            END IF;
            
            -- Calculate new stock (can go negative)
            new_stock := current_stock - allocated_qty;
            
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
                format('Material allocated for customer: %s (Qty: %s, Status: confirmed)', NEW.name, allocated_qty),
                user_id,
                NOW()
            );
            
        END LOOP;
        
        -- Log successful allocation confirmation
        RAISE NOTICE 'Material allocation confirmed for customer % - stock quantities updated', NEW.name;
        
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
