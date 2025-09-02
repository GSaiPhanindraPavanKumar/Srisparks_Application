-- Simplified Material Allocation - Add columns to existing customers table
-- This approach leverages existing infrastructure instead of creating new tables

-- Add material allocation columns to customers table
ALTER TABLE customers ADD COLUMN IF NOT EXISTS material_allocation_plan TEXT; -- JSON string of allocation plan
ALTER TABLE customers ADD COLUMN IF NOT EXISTS material_allocation_status TEXT DEFAULT 'pending' CHECK (
  material_allocation_status IN ('pending', 'planned', 'allocated', 'delivered', 'completed')
);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS material_allocation_date TIMESTAMPTZ;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS material_allocated_by_id UUID REFERENCES users(id);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS material_delivery_date TIMESTAMPTZ;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS material_allocation_notes TEXT;

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_customers_material_allocation_status ON customers(material_allocation_status);
CREATE INDEX IF NOT EXISTS idx_customers_material_allocated_by_id ON customers(material_allocated_by_id);

-- Update existing phase enum to include material allocation if not already present
-- Note: This may need to be adjusted based on your existing phase values
-- ALTER TYPE customer_phase_enum ADD VALUE IF NOT EXISTS 'material_allocation';

-- Create a view for easy material allocation reporting
CREATE OR REPLACE VIEW customer_material_allocations AS
SELECT 
    c.id as customer_id,
    c.name as customer_name,
    c.office_id,
    o.name as office_name,
    c.current_phase,
    c.material_allocation_status,
    c.material_allocation_plan,
    c.material_allocation_date,
    c.material_allocated_by_id,
    u.full_name as allocated_by_name,
    c.material_delivery_date,
    c.material_allocation_notes,
    c.kw,
    c.estimated_kw,
    c.amount_total,
    c.created_at,
    c.updated_at
FROM customers c
LEFT JOIN offices o ON c.office_id = o.id
LEFT JOIN users u ON c.material_allocated_by_id = u.id
WHERE c.is_active = true
AND c.current_phase IN ('material_allocation', 'material', 'installation', 'commissioning', 'completed')
ORDER BY c.material_allocation_date DESC NULLS LAST, c.created_at DESC;

-- Create function to auto-advance customer phase when materials are delivered
CREATE OR REPLACE FUNCTION advance_customer_phase_on_material_delivery()
RETURNS TRIGGER AS $$
BEGIN
    -- When material allocation status changes to 'delivered', advance to installation phase
    IF NEW.material_allocation_status = 'delivered' AND OLD.material_allocation_status != 'delivered' THEN
        NEW.current_phase = 'installation';
        NEW.phase_updated_date = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic phase advancement
DROP TRIGGER IF EXISTS trigger_advance_phase_on_material_delivery ON customers;
CREATE TRIGGER trigger_advance_phase_on_material_delivery
    BEFORE UPDATE ON customers
    FOR EACH ROW
    WHEN (NEW.material_allocation_status IS DISTINCT FROM OLD.material_allocation_status)
    EXECUTE FUNCTION advance_customer_phase_on_material_delivery();

-- Create function to log material allocations in stock_log table
CREATE OR REPLACE FUNCTION log_material_allocation_to_stock()
RETURNS TRIGGER AS $$
DECLARE
    allocation_plan JSONB;
    allocation_item JSONB;
    stock_item_record RECORD;
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
                    
                    IF stock_item_record.id IS NOT NULL AND (allocation_item->>'allocated_quantity')::INTEGER > 0 THEN
                        -- Check if enough stock is available
                        IF stock_item_record.current_stock >= (allocation_item->>'allocated_quantity')::INTEGER THEN
                            -- Update stock
                            UPDATE stock_items 
                            SET current_stock = current_stock - (allocation_item->>'allocated_quantity')::INTEGER,
                                updated_at = NOW()
                            WHERE id = stock_item_record.id;
                            
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
                                work_id,
                                created_at
                            ) VALUES (
                                stock_item_record.id,
                                'decrease',
                                -(allocation_item->>'allocated_quantity')::INTEGER,
                                stock_item_record.current_stock,
                                stock_item_record.current_stock - (allocation_item->>'allocated_quantity')::INTEGER,
                                'Material allocation for customer: ' || NEW.name || ' (ID: ' || NEW.id || ')',
                                NEW.office_id,
                                NEW.material_allocated_by_id,
                                NEW.id,
                                NOW()
                            );
                        ELSE
                            -- Log shortage (for reporting purposes)
                            RAISE NOTICE 'Insufficient stock for item %. Required: %, Available: %',
                                allocation_item->>'item_name',
                                allocation_item->>'allocated_quantity',
                                stock_item_record.current_stock;
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

-- Create trigger for stock logging
DROP TRIGGER IF EXISTS trigger_log_material_allocation_to_stock ON customers;
CREATE TRIGGER trigger_log_material_allocation_to_stock
    AFTER UPDATE ON customers
    FOR EACH ROW
    WHEN (NEW.material_allocation_status IS DISTINCT FROM OLD.material_allocation_status)
    EXECUTE FUNCTION log_material_allocation_to_stock();

-- Migration summary
DO $$
DECLARE
    total_customers INTEGER;
    material_phase_customers INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_customers FROM customers WHERE is_active = true;
    SELECT COUNT(*) INTO material_phase_customers FROM customers 
    WHERE current_phase IN ('material_allocation', 'material') AND is_active = true;

    RAISE NOTICE 'Simplified Material Allocation Migration Summary:';
    RAISE NOTICE '  Total active customers: %', total_customers;
    RAISE NOTICE '  Customers in material phase: %', material_phase_customers;
    RAISE NOTICE '  Columns added to customers table:';
    RAISE NOTICE '    - material_allocation_plan (TEXT/JSON)';
    RAISE NOTICE '    - material_allocation_status';
    RAISE NOTICE '    - material_allocation_date';
    RAISE NOTICE '    - material_allocated_by_id';
    RAISE NOTICE '    - material_delivery_date';
    RAISE NOTICE '    - material_allocation_notes';
    RAISE NOTICE '  Views created:';
    RAISE NOTICE '    - customer_material_allocations';
    RAISE NOTICE '  Functions created:';
    RAISE NOTICE '    - advance_customer_phase_on_material_delivery()';
    RAISE NOTICE '    - log_material_allocation_to_stock()';
    RAISE NOTICE '  Leverages existing stock_log table for tracking';
    RAISE NOTICE 'Simplified material allocation system completed!';
END $$;
