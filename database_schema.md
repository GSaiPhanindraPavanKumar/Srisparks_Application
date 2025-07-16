# Srisparks Workforce Management Database Schema

This document outlines the PostgreSQL database schema for the Srisparks Workforce Management App using Supabase.

## Database Tables

### 1. Users Table
Stores user information with role-based access control.

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  phone_number TEXT,
  role TEXT NOT NULL CHECK (role IN ('director', 'manager', 'employee')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending_approval')),
  is_lead BOOLEAN DEFAULT FALSE,
  office_id UUID REFERENCES offices(id),
  reporting_to_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB
);
```

**Note:** The `is_lead` field is used to designate employees as leads. Only employees can be leads (directors and managers cannot have the lead flag).

### 2. Offices Table
Stores office/branch information.

```sql
CREATE TABLE offices (
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
```

### 3. Customers Table
Stores customer information.

```sql
CREATE TABLE customers (
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
```

### 4. Work Table
Stores work assignments and their status.

```sql
CREATE TABLE work (
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
```

### 5. Activity Logs Table
Stores audit trail of all user activities.

```sql
CREATE TABLE activity_logs (
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
```

## Row Level Security (RLS) Policies

### Users Table Policies

```sql
-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

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

-- Users can see their own profile
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT TO authenticated
  USING (id = auth.uid());

-- Similar policies for INSERT, UPDATE, DELETE operations
```

### Work Table Policies

```sql
-- Enable RLS
ALTER TABLE work ENABLE ROW LEVEL SECURITY;

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
```

## Database Functions

### 1. Get User Hierarchy Function
```sql
CREATE OR REPLACE FUNCTION get_user_hierarchy(user_id UUID)
RETURNS TABLE(
  id UUID,
  email TEXT,
  full_name TEXT,
  role TEXT,
  level INTEGER
) AS $$
BEGIN
  RETURN QUERY
  WITH RECURSIVE user_tree AS (
    SELECT u.id, u.email, u.full_name, u.role, 0 as level
    FROM users u
    WHERE u.id = user_id
    
    UNION ALL
    
    SELECT u.id, u.email, u.full_name, u.role, ut.level + 1
    FROM users u
    JOIN user_tree ut ON u.reporting_to_id = ut.id
  )
  SELECT * FROM user_tree;
END;
$$ LANGUAGE plpgsql;
```

### 2. Update Timestamp Function
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables
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
```

## Edge Functions

### 1. Create User Function
This function is called by directors/managers to create new users.

```javascript
// supabase/functions/create-user/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { email, password, full_name, role, phone_number, office_id, reporting_to_id } = await req.json()

    // Get current user to check permissions
    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user } } = await supabaseClient.auth.getUser(token)

    if (!user) {
      return new Response('Unauthorized', { status: 401, headers: corsHeaders })
    }

    // Check if user has permission to create users
    const { data: currentUser } = await supabaseClient
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single()

    if (!currentUser || !['director', 'manager'].includes(currentUser.role)) {
      return new Response('Forbidden', { status: 403, headers: corsHeaders })
    }

    // Create auth user
    const { data: authUser, error: authError } = await supabaseClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true
    })

    if (authError) {
      return new Response(JSON.stringify({ error: authError.message }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Create user profile
    const { data: userProfile, error: profileError } = await supabaseClient
      .from('users')
      .insert({
        id: authUser.user.id,
        email,
        full_name,
        role,
        phone_number,
        office_id,
        reporting_to_id,
        status: role === 'lead' ? 'pending_approval' : 'active'
      })
      .select()
      .single()

    if (profileError) {
      return new Response(JSON.stringify({ error: profileError.message }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    return new Response(JSON.stringify(userProfile), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
```

## Indexes for Performance

```sql
-- Users table indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_office_id ON users(office_id);
CREATE INDEX idx_users_reporting_to_id ON users(reporting_to_id);
CREATE INDEX idx_users_status ON users(status);

-- Work table indexes
CREATE INDEX idx_work_assigned_to_id ON work(assigned_to_id);
CREATE INDEX idx_work_assigned_by_id ON work(assigned_by_id);
CREATE INDEX idx_work_customer_id ON work(customer_id);
CREATE INDEX idx_work_office_id ON work(office_id);
CREATE INDEX idx_work_status ON work(status);
CREATE INDEX idx_work_priority ON work(priority);
CREATE INDEX idx_work_due_date ON work(due_date);
CREATE INDEX idx_work_created_at ON work(created_at);

-- Activity logs indexes
CREATE INDEX idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX idx_activity_logs_activity_type ON activity_logs(activity_type);
CREATE INDEX idx_activity_logs_entity_id ON activity_logs(entity_id);
CREATE INDEX idx_activity_logs_created_at ON activity_logs(created_at);

-- Customers table indexes
CREATE INDEX idx_customers_office_id ON customers(office_id);
CREATE INDEX idx_customers_is_active ON customers(is_active);
CREATE INDEX idx_customers_email ON customers(email);
```

## Sample Data

```sql
-- Insert sample office
INSERT INTO offices (id, name, address, city, state, country) VALUES
('550e8400-e29b-41d4-a716-446655440000', 'Main Office', '123 Business St', 'New York', 'NY', 'USA');

-- Insert sample director
INSERT INTO users (id, email, full_name, role, office_id) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'director@srisparks.com', 'John Director', 'director', '550e8400-e29b-41d4-a716-446655440000');

-- Insert sample manager
INSERT INTO users (id, email, full_name, role, office_id, reporting_to_id) VALUES
('550e8400-e29b-41d4-a716-446655440002', 'manager@srisparks.com', 'Jane Manager', 'manager', '550e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440001');

-- Insert sample customer
INSERT INTO customers (id, name, email, company_name, office_id) VALUES
('550e8400-e29b-41d4-a716-446655440003', 'ABC Corp', 'contact@abccorp.com', 'ABC Corporation', '550e8400-e29b-41d4-a716-446655440000');
```

This schema provides a solid foundation for the Srisparks Workforce Management App with proper security, relationships, and performance optimizations.
