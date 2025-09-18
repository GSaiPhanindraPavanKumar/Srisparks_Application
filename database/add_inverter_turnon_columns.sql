-- Add inverter turnon columns to customers table
-- This SQL script adds the columns for inverter turnon tracking

-- Add the inverter turnon columns
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS date_of_inverter TIMESTAMP,
ADD COLUMN IF NOT EXISTS inverter_updated_by UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS inverter_updated_time TIMESTAMP;

-- Add comments for documentation
COMMENT ON COLUMN customers.date_of_inverter IS 'The date when the inverter turnon was completed';
COMMENT ON COLUMN customers.inverter_updated_by IS 'ID of the user who updated the inverter turnon record';
COMMENT ON COLUMN customers.inverter_updated_time IS 'Timestamp when the inverter turnon record was last updated';