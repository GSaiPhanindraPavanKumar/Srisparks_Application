-- Simplified Stock Management System Database Schema
-- Simple stock tracking with items, quantities, and logs

-- 1. Stock Items Table (Simplified)
-- Stores basic stock items with current quantities
CREATE TABLE IF NOT EXISTS stock_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  current_stock INTEGER NOT NULL DEFAULT 0,
  office_id UUID NOT NULL REFERENCES offices(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Stock Log Table
-- Records all stock changes for audit purposes
CREATE TABLE IF NOT EXISTS stock_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stock_item_id UUID NOT NULL REFERENCES stock_items(id),
  office_id UUID NOT NULL REFERENCES offices(id),
  action_type TEXT NOT NULL CHECK (action_type IN ('add', 'decrease', 'correction')),
  quantity_change INTEGER NOT NULL, -- positive for add, negative for decrease
  previous_stock INTEGER NOT NULL,
  new_stock INTEGER NOT NULL,
  reason TEXT,
  work_id UUID REFERENCES work(id), -- If related to work order
  user_id UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_stock_items_office_id ON stock_items(office_id);
CREATE INDEX IF NOT EXISTS idx_stock_items_name ON stock_items(name);

CREATE INDEX IF NOT EXISTS idx_stock_log_stock_item_id ON stock_log(stock_item_id);
CREATE INDEX IF NOT EXISTS idx_stock_log_office_id ON stock_log(office_id);
CREATE INDEX IF NOT EXISTS idx_stock_log_created_at ON stock_log(created_at);
CREATE INDEX IF NOT EXISTS idx_stock_log_work_id ON stock_log(work_id);

-- Row Level Security (RLS) Policies
-- Users can only see stock data from their office (except directors)

-- Stock Items RLS
ALTER TABLE stock_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view stock items from their office or all if director"
  ON stock_items FOR SELECT
  USING (
    auth.uid() IN (
      SELECT id FROM users 
      WHERE id = auth.uid() 
      AND (
        role = 'director' 
        OR office_id = stock_items.office_id
      )
    )
  );

CREATE POLICY "Managers and above can manage stock items"
  ON stock_items FOR ALL
  USING (
    auth.uid() IN (
      SELECT id FROM users 
      WHERE id = auth.uid() 
      AND role IN ('director', 'manager')
      AND (role = 'director' OR office_id = stock_items.office_id)
    )
  );

-- Stock Log RLS
ALTER TABLE stock_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view stock log from their office or all if director"
  ON stock_log FOR SELECT
  USING (
    auth.uid() IN (
      SELECT id FROM users 
      WHERE id = auth.uid() 
      AND (
        role = 'director' 
        OR office_id = stock_log.office_id
      )
    )
  );

CREATE POLICY "Users can insert stock log for their office"
  ON stock_log FOR INSERT
  WITH CHECK (
    auth.uid() IN (
      SELECT id FROM users 
      WHERE id = auth.uid() 
      AND (
        role = 'director' 
        OR office_id = stock_log.office_id
      )
    )
  );

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_stock_items_updated_at
  BEFORE UPDATE ON stock_items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Sample data insertion (optional)
-- Uncomment the lines below if you want to insert sample data

-- INSERT INTO stock_items (name, current_stock, office_id) 
-- SELECT 
--   'Sample Item',
--   10,
--   id
-- FROM offices 
-- WHERE NOT EXISTS (SELECT 1 FROM stock_items)
-- LIMIT 1;

COMMENT ON TABLE stock_items IS 'Master data for all stock items with current quantities';
COMMENT ON TABLE stock_log IS 'Audit trail of all stock changes and movements';
