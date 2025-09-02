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
  office_id UUID REFERENCES offices(id), -- NULL for directors (indicates access to all offices)
  reporting_to_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB
);
```

**Note:** The `is_lead` field is used to designate employees as leads. Only employees can be leads (directors and managers cannot have the lead flag).

**Office Access Rules:**
- **Directors**: `office_id` should be NULL (indicates access to all offices)
- **Managers**: `office_id` must reference a specific office (access to that office only)
- **Employees**: `office_id` must reference a specific office (access to that office only)

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
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  metadata JSONB
);
```

### 3. Customers Table
Stores customer information and solar installation project lifecycle.

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
  kw INTEGER,
  is_active BOOLEAN DEFAULT TRUE,
  office_id UUID NOT NULL REFERENCES offices(id),
  added_by_id UUID NOT NULL REFERENCES users(id),
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  
  -- Project Phase Tracking
  current_phase TEXT DEFAULT 'application' CHECK (current_phase IN (
    'application', 'amount', 'material_allocation', 'material_delivery', 
    'installation', 'documentation', 'meter_connection', 
    'inverter_turnon', 'completed', 'service_phase'
  )),
  
  -- 1. APPLICATION PHASE
  application_date TIMESTAMPTZ DEFAULT NOW(),
  application_details JSONB, -- Site survey data, requirements, customer preferences
  application_status TEXT DEFAULT 'pending' CHECK (application_status IN ('pending', 'approved', 'rejected')),
  application_approved_by_id UUID REFERENCES users(id),
  application_approval_date TIMESTAMPTZ,
  application_notes TEXT,
  
  -- Manager Recommendation Fields
  manager_recommendation TEXT CHECK (manager_recommendation IN ('approve', 'reject')),
  manager_recommended_by_id UUID REFERENCES users(id),
  manager_recommendation_date TIMESTAMPTZ,
  manager_recommendation_comment TEXT,
  
  -- Site Survey Status (Controls approval workflow)
  -- Survey Pending: site_survey_completed = FALSE AND site_survey_technician_id = NULL
  -- Survey Ongoing: site_survey_completed = FALSE AND site_survey_technician_id != NULL  
  -- Survey Completed: site_survey_completed = TRUE
  -- Note: Applications cannot be approved/rejected while survey is pending
  -- Complete Survey: Anyone can complete pending surveys using "Complete Site Survey" button
  --   - Captures survey date and optional survey details
  --   - All survey fields are optional: notes, roof type, area, shading, electrical capacity, system type
  --   - Automatically assigns current user as technician and marks as completed
  --   - Updates application_details with provided survey information
  --   - Enables approval workflow after completion
  -- Survey Data Handling:
  --   - When status is "pending": No detailed survey data is saved to application_details
  --   - When status is "ongoing" or "completed": Detailed survey data (roof type, area, etc.) is saved
  --   - This prevents incomplete/placeholder data from being stored when survey hasn't started
  site_survey_completed BOOLEAN DEFAULT FALSE,
  site_survey_date TIMESTAMPTZ,
  site_survey_technician_id UUID REFERENCES users(id), -- Assigned when survey starts or completes
  site_survey_photos JSONB, -- Photos from site survey
  estimated_kw INTEGER, -- Estimated system capacity
  estimated_cost DECIMAL(12,2), -- Estimated project cost
  feasibility_status TEXT DEFAULT 'pending' CHECK (feasibility_status IN ('pending', 'feasible', 'not_feasible')),
  
  -- Equipment Serial Numbers (will be populated in later phases)
  solar_panels_serial_numbers TEXT, -- String of comma-separated serial numbers
  inverter_serial_numbers TEXT, -- String of comma-separated serial numbers
  electric_meter_service_number TEXT NOT NULL, -- Electric meter service number (mandatory field for all applications)
  
  -- 2. AMOUNT PHASE (Only accessible after application approval)
  -- Amount phase can only be cleared by director or manager
  -- Captures final kW capacity and payment details
  amount_kw INTEGER, -- Final confirmed kW capacity (stored in existing kw column for compatibility)
  amount_total DECIMAL(12,2), -- Total project amount in Rs
  amount_paid DECIMAL(12,2), -- Amount actually paid in Rs
  amount_paid_date TIMESTAMPTZ, -- Date when payment was made
  amount_utr_number TEXT, -- UTR/transaction reference number
  amount_payment_status TEXT DEFAULT 'pending' CHECK (amount_payment_status IN ('pending', 'partial', 'completed')),
  amount_cleared_by_id UUID REFERENCES users(id), -- Director/Manager who cleared the amount phase
  amount_cleared_date TIMESTAMPTZ, -- Date when amount phase was cleared
  amount_notes TEXT, -- Additional notes about payment/amount
  
  -- Note: To make electric_meter_service_number mandatory in existing database, run:
  -- ALTER TABLE customers ALTER COLUMN electric_meter_service_number SET NOT NULL;
  
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
  start_location_latitude DECIMAL(10,8),
  start_location_longitude DECIMAL(11,8),
  complete_location_latitude DECIMAL(10,8),
  complete_location_longitude DECIMAL(11,8),
  completion_response TEXT,
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
CREATE INDEX idx_customers_current_phase ON customers(current_phase);
CREATE INDEX idx_customers_application_status ON customers(application_status);
CREATE INDEX idx_customers_feasibility_status ON customers(feasibility_status);
CREATE INDEX idx_customers_added_by_id ON customers(added_by_id);
CREATE INDEX idx_customers_application_approved_by_id ON customers(application_approved_by_id);
CREATE INDEX idx_customers_site_survey_technician_id ON customers(site_survey_technician_id);
CREATE INDEX idx_customers_electric_meter_service_number ON customers(electric_meter_service_number);
CREATE INDEX idx_customers_amount_payment_status ON customers(amount_payment_status);
CREATE INDEX idx_customers_amount_cleared_by_id ON customers(amount_cleared_by_id);
CREATE INDEX idx_customers_amount_cleared_date ON customers(amount_cleared_date);
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

-- Insert sample customer in Application Phase
INSERT INTO customers (
  id, name, email, phone_number, address, city, state, country, 
  office_id, added_by_id, latitude, longitude, 
  current_phase, application_status, estimated_kw, estimated_cost, 
  application_details
) VALUES (
  '550e8400-e29b-41d4-a716-446655440003', 
  'ABC Corp', 
  'contact@abccorp.com', 
  '+91-9876543210',
  '123 Industrial Area, Sector 5',
  'Vijayawada', 
  'Andhra Pradesh', 
  'India',
  '550e8400-e29b-41d4-a716-446655440000', 
  '550e8400-e29b-41d4-a716-446655440002',
  16.746794, 
  81.7022911,
  'application',
  'pending',
  100,
  850000.00,
  '{"roof_type": "concrete", "roof_area": "2000_sqft", "shading_issues": "minimal", "electrical_capacity": "adequate", "customer_requirements": "grid_tie_system"}'
);

-- Insert another sample customer with approved application
INSERT INTO customers (
  id, name, email, phone_number, address, city, state, country,
  office_id, added_by_id, latitude, longitude,
  current_phase, application_status, feasibility_status, estimated_kw, estimated_cost,
  site_survey_completed, application_approved_by_id, application_approval_date
) VALUES (
  '550e8400-e29b-41d4-a716-446655440004', 
  'XYZ Company', 
  'info@xyzcompany.com', 
  '+91-9876543211',
  '456 Tech Park, Phase 2',
  'Vijayawada', 
  'Andhra Pradesh', 
  'India',
  '550e8400-e29b-41d4-a716-446655440000', 
  '550e8400-e29b-41d4-a716-446655440002',
  16.750000, 
  81.705000,
  'application',
  'approved',
  'feasible',
  50,
  425000.00,
  TRUE,
  '550e8400-e29b-41d4-a716-446655440001',
  '2024-08-10T14:30:00Z'
);
```

This schema provides a solid foundation for the Srisparks Workforce Management App with proper security, relationships, and performance optimizations.
