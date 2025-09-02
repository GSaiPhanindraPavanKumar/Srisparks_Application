-- Database Migration for Multiple Payment System
-- Run this script in your Supabase SQL editor to add the new payment system

-- Add new column for multiple payments data
ALTER TABLE customers ADD COLUMN IF NOT EXISTS amount_payments_data TEXT;

-- Add column for tracking phase update dates
ALTER TABLE customers ADD COLUMN IF NOT EXISTS phase_updated_date TIMESTAMPTZ;

-- Comment on the new column
COMMENT ON COLUMN customers.amount_payments_data IS 'JSON string containing array of payment objects with amount, date, UTR, notes, etc.';

-- Update existing customers with empty payment history if they don't have the new field
UPDATE customers 
SET amount_payments_data = '[]' 
WHERE amount_payments_data IS NULL;

-- Create a function to calculate total amount paid from payment history
CREATE OR REPLACE FUNCTION calculate_total_paid(payments_data TEXT)
RETURNS DECIMAL(12,2) AS $$
DECLARE
    payments_array JSONB;
    payment JSONB;
    total_paid DECIMAL(12,2) := 0;
BEGIN
    -- Return 0 if payments_data is null or empty
    IF payments_data IS NULL OR payments_data = '' OR payments_data = '[]' THEN
        RETURN 0;
    END IF;
    
    -- Parse the JSON
    BEGIN
        payments_array := payments_data::JSONB;
    EXCEPTION WHEN OTHERS THEN
        RETURN 0;
    END;
    
    -- Sum up all payment amounts
    FOR payment IN SELECT * FROM jsonb_array_elements(payments_array)
    LOOP
        total_paid := total_paid + COALESCE((payment->>'amount')::DECIMAL(12,2), 0);
    END LOOP;
    
    RETURN total_paid;
END;
$$ LANGUAGE plpgsql;

-- Create a function to calculate payment status
CREATE OR REPLACE FUNCTION calculate_payment_status(total_amount DECIMAL(12,2), payments_data TEXT)
RETURNS TEXT AS $$
DECLARE
    paid_amount DECIMAL(12,2);
BEGIN
    paid_amount := calculate_total_paid(payments_data);
    
    IF total_amount IS NULL OR total_amount <= 0 THEN
        RETURN 'pending';
    END IF;
    
    IF paid_amount >= total_amount THEN
        RETURN 'completed';
    ELSIF paid_amount > 0 THEN
        RETURN 'partial';
    ELSE
        RETURN 'pending';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Migrate existing payment data to the new system
-- This will create payment entries for customers who have existing payment data
UPDATE customers 
SET amount_payments_data = CASE 
    WHEN amount_paid IS NOT NULL AND amount_paid > 0 THEN
        '[{
            "id": "' || extract(epoch from COALESCE(amount_paid_date, now())) || '",
            "amount": ' || amount_paid || ',
            "date": "' || COALESCE(amount_paid_date, now())::text || '",
            "utr_number": "' || COALESCE(amount_utr_number, '') || '",
            "notes": "Migrated from legacy payment data"' ||
            CASE 
                WHEN added_by_id IS NOT NULL THEN ',"added_by_id": "' || added_by_id::text || '"'
                ELSE ''
            END || ',
            "added_at": "' || now()::text || '"
        }]'
    ELSE '[]'
END
WHERE amount_payments_data = '[]' 
AND amount_paid IS NOT NULL 
AND amount_paid > 0;

-- Update payment status based on new calculation
UPDATE customers 
SET amount_payment_status = calculate_payment_status(amount_total, amount_payments_data)
WHERE amount_total IS NOT NULL;

-- Auto-update customers to material_allocation phase if payment is completed
UPDATE customers 
SET current_phase = 'material_allocation'
WHERE current_phase = 'amount' 
AND calculate_payment_status(amount_total, amount_payments_data) = 'completed';

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_customers_amount_payments_data ON customers USING GIN ((amount_payments_data::jsonb));
CREATE INDEX IF NOT EXISTS idx_customers_amount_total ON customers(amount_total);
CREATE INDEX IF NOT EXISTS idx_customers_current_phase_amount_status ON customers(current_phase, amount_payment_status);

-- Create a trigger to auto-update legacy fields when amount_payments_data changes
CREATE OR REPLACE FUNCTION update_legacy_payment_fields()
RETURNS TRIGGER AS $$
DECLARE
    payments_array JSONB;
    latest_payment JSONB;
    total_paid DECIMAL(12,2);
BEGIN
    -- Calculate total paid amount
    total_paid := calculate_total_paid(NEW.amount_payments_data);
    
    -- Update legacy amount_paid field
    NEW.amount_paid := total_paid;
    
    -- Update payment status
    NEW.amount_payment_status := calculate_payment_status(NEW.amount_total, NEW.amount_payments_data);
    
    -- Get the latest payment for UTR and date
    IF NEW.amount_payments_data IS NOT NULL AND NEW.amount_payments_data != '[]' THEN
        BEGIN
            payments_array := NEW.amount_payments_data::JSONB;
            
            -- Get the last payment (assuming they are ordered by date)
            IF jsonb_array_length(payments_array) > 0 THEN
                latest_payment := payments_array -> (jsonb_array_length(payments_array) - 1);
                NEW.amount_utr_number := latest_payment->>'utr_number';
                NEW.amount_paid_date := (latest_payment->>'date')::TIMESTAMPTZ;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            -- If JSON parsing fails, keep existing values
        END;
    END IF;
    
    -- Auto-move to next phase if payment is completed and currently in amount phase
    IF NEW.current_phase = 'amount' AND NEW.amount_payment_status = 'completed' THEN
        NEW.current_phase := 'material_allocation';
        NEW.phase_updated_date := NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS trigger_update_legacy_payment_fields ON customers;
CREATE TRIGGER trigger_update_legacy_payment_fields
    BEFORE UPDATE OF amount_payments_data ON customers
    FOR EACH ROW
    EXECUTE FUNCTION update_legacy_payment_fields();

-- Update the existing updated_at trigger to include the new field
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger with the new field
DROP TRIGGER IF EXISTS update_customers_updated_at ON customers;
CREATE TRIGGER update_customers_updated_at 
  BEFORE UPDATE ON customers 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Add a constraint to ensure amount_payments_data is valid JSON
ALTER TABLE customers ADD CONSTRAINT valid_amount_payments_data 
CHECK (amount_payments_data IS NULL OR (amount_payments_data::jsonb IS NOT NULL));

-- Display migration summary
DO $$
DECLARE
    total_customers INTEGER;
    customers_with_payments INTEGER;
    customers_migrated INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_customers FROM customers WHERE is_active = true;
    SELECT COUNT(*) INTO customers_with_payments FROM customers WHERE amount_payments_data != '[]' AND is_active = true;
    SELECT COUNT(*) INTO customers_migrated FROM customers WHERE amount_paid > 0 AND is_active = true;
    
    RAISE NOTICE 'Migration Summary:';
    RAISE NOTICE '  Total active customers: %', total_customers;
    RAISE NOTICE '  Customers with payment history: %', customers_with_payments;
    RAISE NOTICE '  Customers migrated from legacy payment data: %', customers_migrated;
    RAISE NOTICE 'Migration completed successfully!';
END $$;
