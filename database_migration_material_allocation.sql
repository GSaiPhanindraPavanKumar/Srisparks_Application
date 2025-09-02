-- Database Migration for Material Allocation System
-- Run this script in your Supabase SQL editor to add the material allocation system

-- Create material_allocations table to track allocation plans
CREATE TABLE IF NOT EXISTS material_allocations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  office_id UUID NOT NULL REFERENCES offices(id),
  allocated_by_id UUID NOT NULL REFERENCES users(id),
  
  -- Allocation status
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'confirmed', 'delivered', 'cancelled')),
  
  -- Allocation details
  allocation_date TIMESTAMPTZ DEFAULT NOW(),
  delivery_date TIMESTAMPTZ,
  notes TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Metadata for additional info
  metadata JSONB
);

-- Create material_allocation_items table to track individual item allocations
CREATE TABLE IF NOT EXISTS material_allocation_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  allocation_id UUID NOT NULL REFERENCES material_allocations(id) ON DELETE CASCADE,
  stock_item_id UUID NOT NULL REFERENCES stock_items(id),
  
  -- Allocation quantities
  required_quantity INTEGER NOT NULL DEFAULT 0,
  allocated_quantity INTEGER NOT NULL DEFAULT 0,
  delivered_quantity INTEGER DEFAULT 0,
  
  -- Status for this item
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'allocated', 'partial', 'delivered', 'shortage')),
  
  -- Notes specific to this item
  notes TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add material allocation reference to customers table
ALTER TABLE customers ADD COLUMN IF NOT EXISTS material_allocation_id UUID REFERENCES material_allocations(id);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS material_allocation_status TEXT DEFAULT 'pending' CHECK (material_allocation_status IN ('pending', 'planned', 'allocated', 'delivered', 'completed'));

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_material_allocations_customer_id ON material_allocations(customer_id);
CREATE INDEX IF NOT EXISTS idx_material_allocations_office_id ON material_allocations(office_id);
CREATE INDEX IF NOT EXISTS idx_material_allocations_allocated_by_id ON material_allocations(allocated_by_id);
CREATE INDEX IF NOT EXISTS idx_material_allocations_status ON material_allocations(status);
CREATE INDEX IF NOT EXISTS idx_material_allocations_allocation_date ON material_allocations(allocation_date);

CREATE INDEX IF NOT EXISTS idx_material_allocation_items_allocation_id ON material_allocation_items(allocation_id);
CREATE INDEX IF NOT EXISTS idx_material_allocation_items_stock_item_id ON material_allocation_items(stock_item_id);
CREATE INDEX IF NOT EXISTS idx_material_allocation_items_status ON material_allocation_items(status);

CREATE INDEX IF NOT EXISTS idx_customers_material_allocation_id ON customers(material_allocation_id);
CREATE INDEX IF NOT EXISTS idx_customers_material_allocation_status ON customers(material_allocation_status);

-- Create function to update stock when allocation is confirmed
CREATE OR REPLACE FUNCTION update_stock_on_allocation()
RETURNS TRIGGER AS $$
DECLARE
    stock_item_rec RECORD;
    allocation_rec RECORD;
BEGIN
    -- Only process when allocation status changes to 'confirmed'
    IF TG_OP = 'UPDATE' AND OLD.status != 'confirmed' AND NEW.status = 'confirmed' THEN
        
        -- Get allocation details
        SELECT * INTO allocation_rec FROM material_allocations WHERE id = NEW.allocation_id;
        
        -- Update stock quantity and create stock log entry
        SELECT * INTO stock_item_rec FROM stock_items WHERE id = NEW.stock_item_id;
        
        -- Check if we have enough stock
        IF stock_item_rec.current_stock >= NEW.allocated_quantity THEN
            -- Update stock item
            UPDATE stock_items 
            SET current_stock = current_stock - NEW.allocated_quantity,
                updated_at = NOW()
            WHERE id = NEW.stock_item_id;
            
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
                NEW.stock_item_id,
                'decrease',
                -NEW.allocated_quantity,
                stock_item_rec.current_stock,
                stock_item_rec.current_stock - NEW.allocated_quantity,
                'Material allocation for customer: ' || allocation_rec.customer_id,
                allocation_rec.office_id,
                allocation_rec.allocated_by_id,
                allocation_rec.customer_id,
                NOW()
            );
            
            -- Update item status
            NEW.status := 'allocated';
        ELSE
            -- Not enough stock, mark as shortage
            NEW.status := 'shortage';
            RAISE NOTICE 'Insufficient stock for item %. Required: %, Available: %', 
                NEW.stock_item_id, NEW.allocated_quantity, stock_item_rec.current_stock;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for stock updates
DROP TRIGGER IF EXISTS trigger_update_stock_on_allocation ON material_allocation_items;
CREATE TRIGGER trigger_update_stock_on_allocation
    BEFORE UPDATE ON material_allocation_items
    FOR EACH ROW
    EXECUTE FUNCTION update_stock_on_allocation();

-- Create function to calculate allocation status
CREATE OR REPLACE FUNCTION calculate_allocation_status(allocation_id_param UUID)
RETURNS TEXT AS $$
DECLARE
    total_items INTEGER;
    allocated_items INTEGER;
    shortage_items INTEGER;
    delivered_items INTEGER;
    result_status TEXT;
BEGIN
    -- Count items by status
    SELECT 
        COUNT(*),
        COUNT(CASE WHEN status = 'allocated' THEN 1 END),
        COUNT(CASE WHEN status = 'shortage' THEN 1 END),
        COUNT(CASE WHEN status = 'delivered' THEN 1 END)
    INTO total_items, allocated_items, shortage_items, delivered_items
    FROM material_allocation_items 
    WHERE allocation_id = allocation_id_param;
    
    -- Determine overall status
    IF total_items = 0 THEN
        result_status := 'draft';
    ELSIF delivered_items = total_items THEN
        result_status := 'delivered';
    ELSIF shortage_items > 0 THEN
        result_status := 'partial';
    ELSIF allocated_items = total_items THEN
        result_status := 'confirmed';
    ELSE
        result_status := 'draft';
    END IF;
    
    RETURN result_status;
END;
$$ LANGUAGE plpgsql;

-- Create function to update allocation status when items change
CREATE OR REPLACE FUNCTION update_allocation_status()
RETURNS TRIGGER AS $$
DECLARE
    new_status TEXT;
BEGIN
    -- Calculate new status
    new_status := calculate_allocation_status(
        CASE 
            WHEN TG_OP = 'DELETE' THEN OLD.allocation_id
            ELSE NEW.allocation_id
        END
    );
    
    -- Update allocation status
    UPDATE material_allocations 
    SET status = new_status, updated_at = NOW()
    WHERE id = CASE 
        WHEN TG_OP = 'DELETE' THEN OLD.allocation_id
        ELSE NEW.allocation_id
    END;
    
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update allocation status
DROP TRIGGER IF EXISTS trigger_update_allocation_status ON material_allocation_items;
CREATE TRIGGER trigger_update_allocation_status
    AFTER INSERT OR UPDATE OR DELETE ON material_allocation_items
    FOR EACH ROW
    EXECUTE FUNCTION update_allocation_status();

-- Create function to update customer material allocation status
CREATE OR REPLACE FUNCTION update_customer_material_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Update customer material allocation status based on allocation status
    UPDATE customers 
    SET material_allocation_status = CASE
        WHEN NEW.status = 'draft' THEN 'planned'
        WHEN NEW.status = 'confirmed' THEN 'allocated'
        WHEN NEW.status = 'delivered' THEN 'delivered'
        WHEN NEW.status = 'partial' THEN 'allocated'
        ELSE 'pending'
    END,
    updated_at = NOW()
    WHERE id = NEW.customer_id;
    
    -- Auto-advance to next phase if allocation is completed
    IF NEW.status = 'delivered' THEN
        UPDATE customers 
        SET current_phase = 'installation',
            phase_updated_date = NOW()
        WHERE id = NEW.customer_id 
        AND current_phase IN ('material_allocation', 'material');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update customer status
DROP TRIGGER IF EXISTS trigger_update_customer_material_status ON material_allocations;
CREATE TRIGGER trigger_update_customer_material_status
    AFTER UPDATE ON material_allocations
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_material_status();

-- Create triggers for updated_at fields
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers
DROP TRIGGER IF EXISTS update_material_allocations_updated_at ON material_allocations;
CREATE TRIGGER update_material_allocations_updated_at 
  BEFORE UPDATE ON material_allocations 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_material_allocation_items_updated_at ON material_allocation_items;
CREATE TRIGGER update_material_allocation_items_updated_at 
  BEFORE UPDATE ON material_allocation_items 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create a view for easy querying of allocation details
CREATE OR REPLACE VIEW material_allocation_details AS
SELECT 
    ma.id as allocation_id,
    ma.customer_id,
    c.name as customer_name,
    ma.office_id,
    o.name as office_name,
    ma.allocated_by_id,
    u.full_name as allocated_by_name,
    ma.status as allocation_status,
    ma.allocation_date,
    ma.delivery_date,
    ma.notes as allocation_notes,
    mai.id as item_id,
    mai.stock_item_id,
    si.name as item_name,
    si.unit,
    mai.required_quantity,
    mai.allocated_quantity,
    mai.delivered_quantity,
    mai.status as item_status,
    mai.notes as item_notes,
    si.current_stock as available_stock,
    (mai.required_quantity - mai.allocated_quantity) as shortage_quantity
FROM material_allocations ma
LEFT JOIN material_allocation_items mai ON ma.id = mai.allocation_id
LEFT JOIN customers c ON ma.customer_id = c.id
LEFT JOIN offices o ON ma.office_id = o.id
LEFT JOIN users u ON ma.allocated_by_id = u.id
LEFT JOIN stock_items si ON mai.stock_item_id = si.id
ORDER BY ma.allocation_date DESC, ma.created_at DESC;

-- Add RLS policies for security
ALTER TABLE material_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE material_allocation_items ENABLE ROW LEVEL SECURITY;

-- Directors can see all allocations
CREATE POLICY "Directors can view all allocations" ON material_allocations
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'director'
    )
  );

-- Managers can see allocations in their office
CREATE POLICY "Managers can view office allocations" ON material_allocations
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND role IN ('manager', 'director')
      AND (role = 'director' OR office_id = material_allocations.office_id)
    )
  );

-- Similar policies for allocation items
CREATE POLICY "Directors can view all allocation items" ON material_allocation_items
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'director'
    )
  );

CREATE POLICY "Managers can view office allocation items" ON material_allocation_items
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM material_allocations ma
      JOIN users u ON u.id = auth.uid()
      WHERE ma.id = material_allocation_items.allocation_id
      AND (u.role = 'director' OR u.office_id = ma.office_id)
    )
  );

-- Allow INSERT/UPDATE for directors and managers
CREATE POLICY "Directors and managers can manage allocations" ON material_allocations
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND role IN ('director', 'manager')
    )
  );

CREATE POLICY "Directors and managers can manage allocation items" ON material_allocation_items
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM material_allocations ma
      JOIN users u ON u.id = auth.uid()
      WHERE ma.id = material_allocation_items.allocation_id
      AND u.role IN ('director', 'manager')
    )
  );

-- Display migration summary
DO $$
DECLARE
    total_customers INTEGER;
    material_phase_customers INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_customers FROM customers WHERE is_active = true;
    SELECT COUNT(*) INTO material_phase_customers FROM customers 
    WHERE current_phase IN ('material_allocation', 'material') AND is_active = true;
    
    RAISE NOTICE 'Material Allocation Migration Summary:';
    RAISE NOTICE '  Total active customers: %', total_customers;
    RAISE NOTICE '  Customers in material phase: %', material_phase_customers;
    RAISE NOTICE '  Tables created:';
    RAISE NOTICE '    - material_allocations';
    RAISE NOTICE '    - material_allocation_items';
    RAISE NOTICE '  Views created:';
    RAISE NOTICE '    - material_allocation_details';
    RAISE NOTICE '  Functions created:';
    RAISE NOTICE '    - update_stock_on_allocation()';
    RAISE NOTICE '    - calculate_allocation_status()';
    RAISE NOTICE '    - update_allocation_status()';
    RAISE NOTICE '    - update_customer_material_status()';
    RAISE NOTICE 'Material allocation system migration completed successfully!';
END $$;
