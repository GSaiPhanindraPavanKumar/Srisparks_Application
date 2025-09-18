-- Add meter connection columns to customers table
-- This SQL script adds the columns for meter connection tracking

-- Add the meter connection columns
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS date_of_meter TIMESTAMP,
ADD COLUMN IF NOT EXISTS meter_updated_by UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS meter_updated_time TIMESTAMP;

-- Add comments for documentation
COMMENT ON COLUMN customers.date_of_meter IS 'The date when the meter connection was completed';
COMMENT ON COLUMN customers.meter_updated_by IS 'ID of the user who updated the meter connection record';
COMMENT ON COLUMN customers.meter_updated_time IS 'Timestamp when the meter connection record was last updated';
