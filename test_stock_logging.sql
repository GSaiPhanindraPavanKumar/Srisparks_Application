-- Test script to verify stock logging functionality
-- This script can be run in your Supabase SQL editor to check if stock logs are being created

-- 1. Check if stock_log table exists and its structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'stock_log' 
ORDER BY ordinal_position;

-- 2. Check current stock items
SELECT 
    id,
    name,
    current_stock,
    office_id,
    created_at
FROM stock_items 
ORDER BY created_at DESC
LIMIT 10;

-- 3. Check current stock logs
SELECT 
    sl.id,
    si.name as item_name,
    sl.action_type,
    sl.quantity_change,
    sl.previous_stock,
    sl.new_stock,
    sl.reason,
    sl.created_at
FROM stock_log sl
LEFT JOIN stock_items si ON sl.stock_item_id = si.id
ORDER BY sl.created_at DESC
LIMIT 20;

-- 4. Count logs by action type
SELECT 
    action_type,
    COUNT(*) as count
FROM stock_log 
GROUP BY action_type;

-- 5. Check if logs are being created for specific office (replace with actual office_id)
-- SELECT 
--     sl.*,
--     si.name as item_name
-- FROM stock_log sl
-- LEFT JOIN stock_items si ON sl.stock_item_id = si.id
-- WHERE sl.office_id = 'your-office-id-here'
-- ORDER BY sl.created_at DESC;
