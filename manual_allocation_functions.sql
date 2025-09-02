-- Manual function to process material allocation and update stock
-- Can be called directly to test stock deduction for a specific customer

CREATE OR REPLACE FUNCTION manually_process_material_allocation(customer_id UUID)
RETURNS TABLE(
    item_name TEXT,
    item_id UUID,
    allocated_quantity INTEGER,
    stock_before INTEGER,
    stock_after INTEGER,
    status TEXT
) AS $$
DECLARE
    customer_record RECORD;
    allocation_plan JSONB;
    plan_item JSONB;
    current_stock INTEGER;
    new_stock INTEGER;
    user_id UUID;
BEGIN
    -- Get customer record
    SELECT * INTO customer_record
    FROM customers
    WHERE id = customer_id;
    
    IF customer_record IS NULL THEN
        RAISE EXCEPTION 'Customer not found with ID: %', customer_id;
    END IF;
    
    -- Check if customer has confirmed allocation
    IF customer_record.material_allocation_status != 'confirmed' THEN
        RAISE EXCEPTION 'Customer % does not have confirmed allocation status (current: %)', 
            customer_record.name, customer_record.material_allocation_status;
    END IF;
    
    -- Parse allocation plan
    IF customer_record.material_allocation_plan IS NULL OR customer_record.material_allocation_plan = '' THEN
        RAISE EXCEPTION 'No allocation plan found for customer %', customer_record.name;
    END IF;
    
    allocation_plan := customer_record.material_allocation_plan::JSONB;
    user_id := COALESCE(customer_record.material_confirmed_by_id, customer_record.material_allocated_by_id);
    
    -- Process each item and return results
    FOR plan_item IN SELECT * FROM jsonb_array_elements(allocation_plan->'items')
    LOOP
        item_id := (plan_item->>'item_id')::UUID;
        allocated_quantity := (plan_item->>'allocated_quantity')::INTEGER;
        
        -- Get item name and current stock
        SELECT si.item_name, si.stock_quantity 
        INTO item_name, current_stock
        FROM stock_items si
        WHERE si.id = item_id;
        
        IF item_name IS NULL THEN
            item_name := 'Unknown Item';
            current_stock := 0;
            stock_after := 0;
            status := 'ERROR: Item not found';
        ELSE
            -- Calculate new stock
            new_stock := current_stock - allocated_quantity;
            
            -- Update stock
            UPDATE stock_items
            SET 
                stock_quantity = new_stock,
                updated_at = NOW()
            WHERE stock_items.id = item_id;
            
            stock_after := new_stock;
            status := 'SUCCESS';
            
            -- Create stock log
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
                -allocated_quantity,
                current_stock,
                new_stock,
                'material_allocation',
                customer_id,
                format('Manual allocation processing for customer: %s', customer_record.name),
                user_id,
                NOW()
            );
        END IF;
        
        stock_before := current_stock;
        RETURN NEXT;
    END LOOP;
    
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- Function to check allocation status and stock logs for a customer
CREATE OR REPLACE FUNCTION check_customer_allocation_status(customer_id UUID)
RETURNS TABLE(
    customer_name TEXT,
    allocation_status TEXT,
    planned_by TEXT,
    planned_date TIMESTAMP,
    allocated_by TEXT,
    confirmed_by TEXT,
    confirmed_date TIMESTAMP,
    allocation_date TIMESTAMP,
    total_items INTEGER,
    stock_logs_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.name,
        c.material_allocation_status,
        u1.full_name,
        c.material_planned_date,
        u2.full_name,
        u3.full_name,
        c.material_confirmed_date,
        c.material_allocation_date,
        CASE 
            WHEN c.material_allocation_plan IS NOT NULL 
            THEN jsonb_array_length((c.material_allocation_plan::JSONB)->'items')
            ELSE 0
        END,
        (
            SELECT COUNT(*)::INTEGER
            FROM stock_logs sl
            WHERE sl.reference_type = 'material_allocation'
            AND sl.reference_id = customer_id
        )
    FROM customers c
    LEFT JOIN users u1 ON c.material_planned_by_id = u1.id
    LEFT JOIN users u2 ON c.material_allocated_by_id = u2.id
    LEFT JOIN users u3 ON c.material_confirmed_by_id = u3.id
    WHERE c.id = customer_id;
END;
$$ LANGUAGE plpgsql;
