-- Material Allocation Database Verification Script
-- Run this in your Supabase SQL editor to check if migration was applied

-- 1. Check if material allocation columns exist in customers table
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'customers'
AND column_name LIKE 'material_%'
ORDER BY column_name;

-- 2. Check if triggers exist
SELECT trigger_name, event_manipulation, action_timing, event_object_table
FROM information_schema.triggers
WHERE trigger_name LIKE '%material%'
OR trigger_name LIKE '%stock%';

-- 3. Check if functions exist
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_name LIKE '%material%'
OR routine_name LIKE '%stock%';

-- 4. Check sample customer with material allocation data
SELECT 
    name,
    current_phase,
    material_allocation_status,
    material_allocation_plan IS NOT NULL as has_plan,
    material_allocation_date
FROM customers
WHERE material_allocation_plan IS NOT NULL
LIMIT 5;

-- 5. Check stock_log entries related to material allocation
SELECT 
    sl.created_at,
    sl.action_type,
    sl.quantity_change,
    sl.reason,
    si.name as item_name
FROM stock_log sl
JOIN stock_items si ON sl.stock_item_id = si.id
WHERE sl.reason ILIKE '%material allocation%'
ORDER BY sl.created_at DESC
LIMIT 10;

-- 6. Test if material allocation view exists
SELECT COUNT(*) as allocation_view_exists
FROM information_schema.views
WHERE table_name = 'customer_material_allocations';

-- 7. Check if enum values exist (if using enum)
SELECT unnest(enum_range(NULL::text)) as status_values
FROM pg_type
WHERE typname = 'material_allocation_status_enum';

-- 8. Test trigger functionality manually (IMPORTANT!)
-- Replace UUIDs with actual values from your database before running
-- STEP 1: First get a real customer ID and stock item ID:
SELECT 
    'Customer ID: ' || c.id as customer_info,
    'Stock Item ID: ' || si.id as stock_item_info,
    'Current Stock: ' || si.current_stock as current_stock
FROM customers c
CROSS JOIN stock_items si
WHERE c.current_phase = 'material_allocation'
AND si.current_stock > 0
LIMIT 1;

-- STEP 2: After getting real IDs, uncomment and modify this test:
/*
DO $$
DECLARE
    test_customer_id UUID := 'REPLACE-WITH-REAL-CUSTOMER-ID';
    test_stock_item_id UUID := 'REPLACE-WITH-REAL-STOCK-ITEM-ID';
    test_plan TEXT := '{
        "items": [
            {
                "stock_item_id": "REPLACE-WITH-REAL-STOCK-ITEM-ID",
                "item_name": "Test Item",
                "required_quantity": 1,
                "allocated_quantity": 1
            }
        ]
    }';
    initial_stock INTEGER;
    final_stock INTEGER;
BEGIN
    -- Get initial stock
    SELECT current_stock INTO initial_stock FROM stock_items WHERE id = test_stock_item_id;
    
    -- Test the trigger
    UPDATE customers 
    SET 
        material_allocation_plan = test_plan,
        material_allocation_status = 'allocated'
    WHERE id = test_customer_id;
    
    -- Check final stock
    SELECT current_stock INTO final_stock FROM stock_items WHERE id = test_stock_item_id;
    
    -- Report results
    RAISE NOTICE 'TRIGGER TEST RESULTS:';
    RAISE NOTICE 'Initial stock: %', initial_stock;
    RAISE NOTICE 'Final stock: %', final_stock;
    RAISE NOTICE 'Stock deducted: %', (initial_stock - final_stock);
    RAISE NOTICE 'Expected deduction: 1';
    
    IF (initial_stock - final_stock) = 1 THEN
        RAISE NOTICE 'SUCCESS: Trigger is working correctly!';
    ELSE
        RAISE NOTICE 'FAILED: Trigger did not deduct stock properly!';
    END IF;
END $$;
*/
