-- Query to identify the correct column names in stock_items table
-- Run this first to see the actual structure

-- Check the structure of stock_items table
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'stock_items' 
ORDER BY ordinal_position;

-- Alternative way to see the structure
\d stock_items

-- Sample query to see actual data and column names
SELECT * FROM stock_items LIMIT 5;

-- Check if any of these common column names exist:
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'stock_items' AND column_name = 'stock_quantity') 
        THEN 'stock_quantity column exists'
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'stock_items' AND column_name = 'quantity') 
        THEN 'quantity column exists'
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'stock_items' AND column_name = 'stock') 
        THEN 'stock column exists'
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'stock_items' AND column_name = 'available_quantity') 
        THEN 'available_quantity column exists'
        ELSE 'None of the expected columns found'
    END as column_status;
