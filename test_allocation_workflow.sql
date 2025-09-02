-- Test script to verify material allocation workflow is working correctly
-- Run this after applying the comprehensive fix

-- 1. Check if any customers have confirmed allocations
SELECT 
    c.name,
    c.material_allocation_status,
    c.material_planned_date,
    c.material_confirmed_date,
    c.material_allocation_date,
    CASE 
        WHEN c.material_allocation_plan IS NOT NULL 
        THEN jsonb_array_length((c.material_allocation_plan::JSONB)->'items')
        ELSE 0
    END as item_count
FROM customers c
WHERE c.material_allocation_status IN ('planned', 'allocated', 'confirmed')
ORDER BY c.material_allocation_status, c.name;

-- 2. Check recent stock logs for material allocations
SELECT 
    sl.created_at,
    sl.transaction_type,
    si.item_name,
    sl.quantity_changed,
    sl.quantity_before,
    sl.quantity_after,
    sl.notes,
    u.full_name as created_by
FROM stock_logs sl
JOIN stock_items si ON sl.stock_item_id = si.id
LEFT JOIN users u ON sl.created_by_id = u.id
WHERE sl.reference_type = 'material_allocation'
ORDER BY sl.created_at DESC
LIMIT 20;

-- 3. Check for any customers with confirmed status but no stock logs
SELECT 
    c.id,
    c.name,
    c.material_allocation_status,
    c.material_confirmed_date,
    COUNT(sl.id) as stock_log_count
FROM customers c
LEFT JOIN stock_logs sl ON (sl.reference_type = 'material_allocation' AND sl.reference_id = c.id)
WHERE c.material_allocation_status = 'confirmed'
GROUP BY c.id, c.name, c.material_allocation_status, c.material_confirmed_date
HAVING COUNT(sl.id) = 0
ORDER BY c.material_confirmed_date DESC;

-- 4. Test function to check specific customer (replace with actual customer ID)
-- SELECT * FROM check_customer_allocation_status('your-customer-id-here');

-- 5. Test manual processing function (replace with actual customer ID)  
-- SELECT * FROM manually_process_material_allocation('your-customer-id-here');
