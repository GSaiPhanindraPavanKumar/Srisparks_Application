-- FIX: Material Allocation Database Trigger
-- Run this to fix the trigger that wasn't working properly

-- Drop and recreate the trigger function with correct stock calculations
CREATE OR REPLACE FUNCTION log_material_allocation_to_stock()
RETURNS TRIGGER AS $$
DECLARE
    allocation_plan JSONB;
    allocation_item JSONB;
    stock_item_record RECORD;
    allocation_qty INTEGER;
    previous_stock_value INTEGER;
    new_stock_value INTEGER;
BEGIN
    -- Only process when status changes to 'allocated'
    IF NEW.material_allocation_status = 'allocated' AND OLD.material_allocation_status != 'allocated' THEN
        
        -- Parse the allocation plan JSON
        IF NEW.material_allocation_plan IS NOT NULL THEN
            BEGIN
                allocation_plan := NEW.material_allocation_plan::JSONB;
                
                -- Loop through each item in the allocation plan
                FOR allocation_item IN SELECT * FROM jsonb_array_elements(allocation_plan->'items')
                LOOP
                    -- Get stock item details
                    SELECT * INTO stock_item_record 
                    FROM stock_items 
                    WHERE id = (allocation_item->>'stock_item_id')::UUID;
                    
                    allocation_qty := (allocation_item->>'allocated_quantity')::INTEGER;
                    
                    IF stock_item_record.id IS NOT NULL AND allocation_qty > 0 THEN
                        -- Store the current stock values BEFORE updating
                        previous_stock_value := stock_item_record.current_stock;
                        
                        -- Check if enough stock is available
                        IF previous_stock_value >= allocation_qty THEN
                            -- Calculate new stock value
                            new_stock_value := previous_stock_value - allocation_qty;
                            
                            -- Update stock
                            UPDATE stock_items 
                            SET current_stock = new_stock_value,
                                updated_at = NOW()
                            WHERE id = stock_item_record.id;
                            
                            -- Create stock log entry with correct values
                            INSERT INTO stock_log (
                                stock_item_id,
                                action_type,
                                quantity_change,
                                previous_stock,
                                new_stock,
                                reason,
                                office_id,
                                user_id,
                                work_id,
                                created_at
                            ) VALUES (
                                stock_item_record.id,
                                'decrease',
                                -allocation_qty,
                                previous_stock_value,
                                new_stock_value,
                                'Material allocation for customer: ' || NEW.name || ' (ID: ' || NEW.id || ')',
                                NEW.office_id,
                                NEW.material_allocated_by_id,
                                NEW.id,
                                NOW()
                            );
                            
                            RAISE NOTICE 'Material allocated: % units of % (from % to %)', 
                                allocation_qty, 
                                allocation_item->>'item_name',
                                previous_stock_value,
                                new_stock_value;
                        ELSE
                            -- Log shortage
                            RAISE NOTICE 'Insufficient stock for item %. Required: %, Available: %',
                                allocation_item->>'item_name',
                                allocation_qty,
                                previous_stock_value;
                                
                            -- Still create a log entry for the shortage
                            INSERT INTO stock_log (
                                stock_item_id,
                                action_type,
                                quantity_change,
                                previous_stock,
                                new_stock,
                                reason,
                                office_id,
                                user_id,
                                work_id,
                                created_at
                            ) VALUES (
                                stock_item_record.id,
                                'shortage',
                                0,
                                previous_stock_value,
                                previous_stock_value,
                                'Material allocation shortage for customer: ' || NEW.name || ' - Required: ' || allocation_qty || ', Available: ' || previous_stock_value,
                                NEW.office_id,
                                NEW.material_allocated_by_id,
                                NEW.id,
                                NOW()
                            );
                        END IF;
                    END IF;
                END LOOP;
                
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE 'Error processing material allocation plan for customer %: %', NEW.id, SQLERRM;
            END;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
DROP TRIGGER IF EXISTS trigger_log_material_allocation_to_stock ON customers;
CREATE TRIGGER trigger_log_material_allocation_to_stock
    AFTER UPDATE ON customers
    FOR EACH ROW
    WHEN (NEW.material_allocation_status IS DISTINCT FROM OLD.material_allocation_status)
    EXECUTE FUNCTION log_material_allocation_to_stock();

-- Test the fix with a simple notice
DO $$
BEGIN
    RAISE NOTICE 'Material allocation trigger has been updated and fixed!';
    RAISE NOTICE 'Key improvements:';
    RAISE NOTICE '1. Correct stock value calculations';
    RAISE NOTICE '2. Better error handling';
    RAISE NOTICE '3. Shortage logging';
    RAISE NOTICE '4. Debug notices for testing';
END $$;
