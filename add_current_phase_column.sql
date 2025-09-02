-- Quick fix to add the missing current_phase column
-- Run this in your Supabase SQL Editor

-- Add the current_phase column
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS current_phase TEXT DEFAULT 'application' CHECK (current_phase IN (
  'application', 'amount', 'material_allocation', 'material_delivery', 
  'installation', 'documentation', 'meter_connection', 
  'inverter_turnon', 'completed', 'service_phase'
));

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_customers_current_phase ON customers(current_phase);

-- Verify the column was added
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customers' AND column_name = 'current_phase') 
        THEN 'SUCCESS: current_phase column added'
        ELSE 'ERROR: current_phase column still missing'
    END as result;

-- Show the column details
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'customers' 
AND column_name = 'current_phase'
AND table_schema = 'public';
</content>
</invoke>
