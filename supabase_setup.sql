-- Srisparks Workforce Management Database Setup
-- Run this script in your Supabase SQL Editor

-- 1. Create Offices Table
CREATE TABLE IF NOT EXISTS offices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  country TEXT,
  phone_number TEXT,
  email TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB
);

-- 2. Create Users Table (Updated with approval workflow)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  phone_number TEXT,
  role TEXT NOT NULL CHECK (role IN ('director', 'manager', 'employee')),
  status TEXT NOT NULL DEFAULT 'inactive' CHECK (status IN ('active', 'inactive')),
  is_lead BOOLEAN DEFAULT FALSE,
  office_id UUID REFERENCES offices(id),
  
  -- Approval workflow columns
  added_by UUID REFERENCES users(id),
  added_time TIMESTAMPTZ DEFAULT NOW(),
  approved_by UUID REFERENCES users(id),
  approved_time TIMESTAMPTZ,
  approval_status TEXT DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB
);

-- 3. Create Customers Table
CREATE TABLE IF NOT EXISTS customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT,
  phone_number TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  country TEXT,
  company_name TEXT,
  tax_id TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  office_id UUID NOT NULL REFERENCES offices(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB
);

-- 4. Create Work Table
CREATE TABLE IF NOT EXISTS work (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  customer_id UUID NOT NULL REFERENCES customers(id),
  assigned_to_id UUID NOT NULL REFERENCES users(id),
  assigned_by_id UUID NOT NULL REFERENCES users(id),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'verified', 'rejected')),
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  due_date TIMESTAMPTZ,
  start_date TIMESTAMPTZ,
  completed_date TIMESTAMPTZ,
  verified_date TIMESTAMPTZ,
  verified_by_id UUID REFERENCES users(id),
  rejection_reason TEXT,
  estimated_hours DECIMAL(5,2),
  actual_hours DECIMAL(5,2),
  office_id UUID NOT NULL REFERENCES offices(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB
);

-- 5. Create Activity Logs Table
CREATE TABLE IF NOT EXISTS activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  activity_type TEXT NOT NULL,
  description TEXT,
  entity_id UUID,
  entity_type TEXT,
  old_data JSONB,
  new_data JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB
);

-- 6. Create Update Timestamp Function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Create Triggers for Updated At
CREATE TRIGGER update_users_updated_at 
  BEFORE UPDATE ON users 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_offices_updated_at 
  BEFORE UPDATE ON offices 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at 
  BEFORE UPDATE ON customers 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_work_updated_at 
  BEFORE UPDATE ON work 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 8. Create Performance Indexes
-- Users table indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_office_id ON users(office_id);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_users_is_lead ON users(is_lead);
CREATE INDEX IF NOT EXISTS idx_users_added_by ON users(added_by);
CREATE INDEX IF NOT EXISTS idx_users_approved_by ON users(approved_by);
CREATE INDEX IF NOT EXISTS idx_users_approval_status ON users(approval_status);
CREATE INDEX IF NOT EXISTS idx_users_added_time ON users(added_time);
CREATE INDEX IF NOT EXISTS idx_users_approved_time ON users(approved_time);

-- Work table indexes
CREATE INDEX IF NOT EXISTS idx_work_assigned_to_id ON work(assigned_to_id);
CREATE INDEX IF NOT EXISTS idx_work_assigned_by_id ON work(assigned_by_id);
CREATE INDEX IF NOT EXISTS idx_work_customer_id ON work(customer_id);
CREATE INDEX IF NOT EXISTS idx_work_office_id ON work(office_id);
CREATE INDEX IF NOT EXISTS idx_work_status ON work(status);
CREATE INDEX IF NOT EXISTS idx_work_priority ON work(priority);
CREATE INDEX IF NOT EXISTS idx_work_due_date ON work(due_date);
CREATE INDEX IF NOT EXISTS idx_work_created_at ON work(created_at);

-- Activity logs indexes
CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_activity_type ON activity_logs(activity_type);
CREATE INDEX IF NOT EXISTS idx_activity_logs_entity_id ON activity_logs(entity_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at);

-- Customers table indexes
CREATE INDEX IF NOT EXISTS idx_customers_office_id ON customers(office_id);
CREATE INDEX IF NOT EXISTS idx_customers_is_active ON customers(is_active);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);

-- 9. Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE offices ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE work ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- 10. Create RLS Policies for Users Table
-- Directors can see all users
CREATE POLICY "Directors can view all users" ON users
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'director'
    )
  );

-- Managers can see users in their office
CREATE POLICY "Managers can view office users" ON users
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND role IN ('manager', 'director')
      AND office_id = users.office_id
    )
  );

-- Leads can see users who report to them
CREATE POLICY "Leads can view reporting users" ON users
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND is_lead = true
      AND id = users.reporting_to_id
    )
  );

-- Users can see their own profile
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT TO authenticated
  USING (id = auth.uid());

-- Directors can insert/update/delete all users
CREATE POLICY "Directors can manage all users" ON users
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'director'
    )
  );

-- Managers can insert employees in their office
CREATE POLICY "Managers can create employees" ON users
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND role = 'manager'
      AND office_id = users.office_id
    )
    AND role = 'employee'
  );

-- 11. Create RLS Policies for Work Table
-- Users can see work assigned to them
CREATE POLICY "Users can view assigned work" ON work
  FOR SELECT TO authenticated
  USING (assigned_to_id = auth.uid());

-- Users can see work they assigned
CREATE POLICY "Users can view work they assigned" ON work
  FOR SELECT TO authenticated
  USING (assigned_by_id = auth.uid());

-- Directors can see all work
CREATE POLICY "Directors can view all work" ON work
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'director'
    )
  );

-- Managers can see work in their office
CREATE POLICY "Managers can view office work" ON work
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND role IN ('manager', 'director')
      AND office_id = work.office_id
    )
  );

-- Leads can see work for users reporting to them
CREATE POLICY "Leads can view team work" ON work
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND is_lead = true
      AND id = (
        SELECT reporting_to_id FROM users WHERE id = work.assigned_to_id
      )
    )
  );

-- Work assignment policies
CREATE POLICY "Directors can assign work" ON work
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'director'
    )
  );

CREATE POLICY "Managers can assign work in office" ON work
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND role = 'manager'
      AND office_id = work.office_id
    )
  );

CREATE POLICY "Leads can assign work to team" ON work
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND is_lead = true
      AND id = (
        SELECT reporting_to_id FROM users WHERE id = work.assigned_to_id
      )
    )
  );

-- 12. Create RLS Policies for Customers Table
-- Directors can see all customers
CREATE POLICY "Directors can view all customers" ON customers
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'director'
    )
  );

-- Managers can see customers in their office
CREATE POLICY "Managers can view office customers" ON customers
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND role IN ('manager', 'director')
      AND office_id = customers.office_id
    )
  );

-- Leads can see customers in their office
CREATE POLICY "Leads can view office customers" ON customers
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND is_lead = true
      AND office_id = customers.office_id
    )
  );

-- 13. Create RLS Policies for Offices Table
-- Directors can see all offices
CREATE POLICY "Directors can view all offices" ON offices
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'director'
    )
  );

-- Managers can see their office
CREATE POLICY "Managers can view own office" ON offices
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND role IN ('manager', 'director')
      AND office_id = offices.id
    )
  );

-- 14. Create RLS Policies for Activity Logs Table
-- Directors can see all activity logs
CREATE POLICY "Directors can view all activity logs" ON activity_logs
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'director'
    )
  );

-- Managers can see activity logs for their office
CREATE POLICY "Managers can view office activity logs" ON activity_logs
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u1
      JOIN users u2 ON u1.office_id = u2.office_id
      WHERE u1.id = auth.uid() 
      AND u1.role IN ('manager', 'director')
      AND u2.id = activity_logs.user_id
    )
  );

-- Users can see their own activity logs
CREATE POLICY "Users can view own activity logs" ON activity_logs
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- 15. Create Utility Functions
-- Function to get user hierarchy
CREATE OR REPLACE FUNCTION get_user_hierarchy(user_id UUID)
RETURNS TABLE(
  id UUID,
  email TEXT,
  full_name TEXT,
  role TEXT,
  is_lead BOOLEAN,
  level INTEGER
) AS $$
BEGIN
  RETURN QUERY
  WITH RECURSIVE user_tree AS (
    SELECT u.id, u.email, u.full_name, u.role, u.is_lead, 0 as level
    FROM users u
    WHERE u.id = user_id
    
    UNION ALL
    
    SELECT u.id, u.email, u.full_name, u.role, u.is_lead, ut.level + 1
    FROM users u
    JOIN user_tree ut ON u.reporting_to_id = ut.id
  )
  SELECT * FROM user_tree;
END;
$$ LANGUAGE plpgsql;

-- Function to check if user can assign work
CREATE OR REPLACE FUNCTION can_assign_work(assigner_id UUID, assignee_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  assigner_role TEXT;
  assigner_is_lead BOOLEAN;
  assigner_office_id UUID;
  assignee_office_id UUID;
  assignee_reporting_to_id UUID;
BEGIN
  -- Get assigner details
  SELECT role, is_lead, office_id 
  INTO assigner_role, assigner_is_lead, assigner_office_id
  FROM users WHERE id = assigner_id;
  
  -- Get assignee details
  SELECT office_id, reporting_to_id 
  INTO assignee_office_id, assignee_reporting_to_id
  FROM users WHERE id = assignee_id;
  
  -- Directors can assign to anyone
  IF assigner_role = 'director' THEN
    RETURN TRUE;
  END IF;
  
  -- Managers can assign to anyone in their office
  IF assigner_role = 'manager' AND assigner_office_id = assignee_office_id THEN
    RETURN TRUE;
  END IF;
  
  -- Leads can assign to users who report to them
  IF assigner_is_lead = TRUE AND assigner_id = assignee_reporting_to_id THEN
    RETURN TRUE;
  END IF;
  
  RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- 16. Insert Sample Data
-- Insert sample office
INSERT INTO offices (id, name, address, city, state, country) VALUES
('550e8400-e29b-41d4-a716-446655440000', 'Main Office', '123 Business St', 'New York', 'NY', 'USA')
ON CONFLICT (id) DO NOTHING;

-- Insert sample director (You'll need to create this user in Supabase Auth first)
-- INSERT INTO users (id, email, full_name, role, office_id) VALUES
-- ('550e8400-e29b-41d4-a716-446655440001', 'director@srisparks.com', 'John Director', 'director', '550e8400-e29b-41d4-a716-446655440000')
-- ON CONFLICT (id) DO NOTHING;

-- Insert sample customer
INSERT INTO customers (id, name, email, company_name, office_id) VALUES
('550e8400-e29b-41d4-a716-446655440003', 'ABC Corp', 'contact@abccorp.com', 'ABC Corporation', '550e8400-e29b-41d4-a716-446655440000')
ON CONFLICT (id) DO NOTHING;

-- Note: Users must be created through Supabase Auth first, then their profiles added to the users table
-- You can use the Edge Function for this or create them manually in the Supabase Dashboard
