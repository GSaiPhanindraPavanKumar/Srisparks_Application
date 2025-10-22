-- Add missing columns to customers table

-- Add meter connection completed date column
ALTER TABLE public.customers 
ADD COLUMN IF NOT EXISTS meter_connection_completed_date timestamp without time zone NULL;

-- Add inverter turnon completed date column  
ALTER TABLE public.customers 
ADD COLUMN IF NOT EXISTS inverter_turnon_completed_date timestamp without time zone NULL;

-- Add project completed date column
ALTER TABLE public.customers 
ADD COLUMN IF NOT EXISTS project_completed_date timestamp without time zone NULL;

-- Add indexes for the new columns for better performance
CREATE INDEX IF NOT EXISTS idx_customers_meter_connection_completed_date 
ON public.customers USING btree (meter_connection_completed_date) 
TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_customers_inverter_turnon_completed_date 
ON public.customers USING btree (inverter_turnon_completed_date) 
TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_customers_project_completed_date 
ON public.customers USING btree (project_completed_date) 
TABLESPACE pg_default;

-- Optional: Add foreign key constraints for tracking who completed each phase
-- (Uncomment if you want to track who completed each phase)

-- ALTER TABLE public.customers 
-- ADD COLUMN IF NOT EXISTS meter_connection_completed_by uuid NULL;
-- 
-- ALTER TABLE public.customers 
-- ADD COLUMN IF NOT EXISTS inverter_turnon_completed_by uuid NULL;
-- 
-- ALTER TABLE public.customers 
-- ADD COLUMN IF NOT EXISTS project_completed_by uuid NULL;
-- 
-- ALTER TABLE public.customers 
-- ADD CONSTRAINT customers_meter_connection_completed_by_fkey 
-- FOREIGN KEY (meter_connection_completed_by) REFERENCES users (id);
-- 
-- ALTER TABLE public.customers 
-- ADD CONSTRAINT customers_inverter_turnon_completed_by_fkey 
-- FOREIGN KEY (inverter_turnon_completed_by) REFERENCES users (id);
-- 
-- ALTER TABLE public.customers 
-- ADD CONSTRAINT customers_project_completed_by_fkey 
-- FOREIGN KEY (project_completed_by) REFERENCES users (id);
-- 
-- CREATE INDEX IF NOT EXISTS idx_customers_meter_connection_completed_by 
-- ON public.customers USING btree (meter_connection_completed_by) 
-- TABLESPACE pg_default;
-- 
-- CREATE INDEX IF NOT EXISTS idx_customers_inverter_turnon_completed_by 
-- ON public.customers USING btree (inverter_turnon_completed_by) 
-- TABLESPACE pg_default;
-- 
-- CREATE INDEX IF NOT EXISTS idx_customers_project_completed_by 
-- ON public.customers USING btree (project_completed_by) 
-- TABLESPACE pg_default;