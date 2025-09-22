-- Migration: Add User Approval Workflow Columns
-- Description: Adds approval workflow columns and removes reporting_to_id
-- Date: 2025-09-22

-- 1. Add new approval workflow columns
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS added_by UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS added_time TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS approved_time TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS approval_status TEXT DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected'));

-- 2. Update existing users to have approval workflow data
-- Set all existing users as approved since they're already active
UPDATE users 
SET approval_status = 'approved', 
    approved_time = created_at,
    added_time = created_at
WHERE approval_status IS NULL OR approval_status = 'pending';

-- 3. Remove the reporting_to_id column (if it exists)
ALTER TABLE users DROP COLUMN IF EXISTS reporting_to_id;

-- 4. Update the status check constraint to ensure only active users can login
-- Note: We'll handle this logic in the application layer and Edge Functions

-- 5. Create indexes for better performance on approval workflow queries
CREATE INDEX IF NOT EXISTS idx_users_added_by ON users(added_by);
CREATE INDEX IF NOT EXISTS idx_users_approved_by ON users(approved_by);
CREATE INDEX IF NOT EXISTS idx_users_approval_status ON users(approval_status);
CREATE INDEX IF NOT EXISTS idx_users_added_time ON users(added_time);
CREATE INDEX IF NOT EXISTS idx_users_approved_time ON users(approved_time);

-- 6. Create a function to automatically approve users added by directors
CREATE OR REPLACE FUNCTION auto_approve_director_users() 
RETURNS TRIGGER AS $$
DECLARE
  creator_role TEXT;
BEGIN
  -- Get the role of the user who added this user
  SELECT role INTO creator_role 
  FROM users 
  WHERE id = NEW.added_by;
  
  -- If added by director, auto-approve
  IF creator_role = 'director' THEN
    NEW.approval_status = 'approved';
    NEW.approved_by = NEW.added_by;
    NEW.approved_time = NOW();
    NEW.status = 'active';
  ELSE
    -- If added by manager/lead, keep pending and set status to inactive
    NEW.approval_status = 'pending';
    NEW.status = 'inactive';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Create trigger to auto-approve users added by directors
DROP TRIGGER IF EXISTS trigger_auto_approve_director_users ON users;
CREATE TRIGGER trigger_auto_approve_director_users
  BEFORE INSERT ON users
  FOR EACH ROW
  WHEN (NEW.added_by IS NOT NULL)
  EXECUTE FUNCTION auto_approve_director_users();

-- 8. Create a function for directors to approve/reject pending users
CREATE OR REPLACE FUNCTION approve_reject_user(
  user_id UUID,
  director_id UUID,
  action TEXT, -- 'approve' or 'reject'
  comments TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
  director_role TEXT;
  user_exists BOOLEAN;
BEGIN
  -- Check if the approver is a director
  SELECT role INTO director_role 
  FROM users 
  WHERE id = director_id AND status = 'active';
  
  IF director_role != 'director' THEN
    RAISE EXCEPTION 'Only directors can approve or reject users';
  END IF;
  
  -- Check if user exists and is pending
  SELECT EXISTS(
    SELECT 1 FROM users 
    WHERE id = user_id AND approval_status = 'pending'
  ) INTO user_exists;
  
  IF NOT user_exists THEN
    RAISE EXCEPTION 'User not found or not pending approval';
  END IF;
  
  -- Update the user based on action
  IF action = 'approve' THEN
    UPDATE users 
    SET approval_status = 'approved',
        approved_by = director_id,
        approved_time = NOW(),
        status = 'active'
    WHERE id = user_id;
  ELSIF action = 'reject' THEN
    UPDATE users 
    SET approval_status = 'rejected',
        approved_by = director_id,
        approved_time = NOW(),
        status = 'inactive'
    WHERE id = user_id;
  ELSE
    RAISE EXCEPTION 'Invalid action. Use "approve" or "reject"';
  END IF;
  
  -- Log the approval action
  INSERT INTO activity_logs (
    user_id, 
    activity_type, 
    description,
    entity_id,
    entity_type,
    metadata
  ) VALUES (
    director_id,
    'user_' || action,
    'User ' || action || 'ed by director',
    user_id,
    'user',
    jsonb_build_object(
      'action', action,
      'comments', comments,
      'approved_user_id', user_id
    )
  );
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 9. Create RLS policies for approval workflow
-- Directors can see all users including pending ones
CREATE POLICY "Directors can view all users for approval" ON users
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'director' AND status = 'active'
    )
  );

-- Users can only see approved/active users (except directors who see all)
CREATE POLICY "Users can view approved users" ON users
  FOR SELECT TO authenticated
  USING (
    approval_status = 'approved' AND status = 'active'
    OR EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'director' AND status = 'active'
    )
    OR id = auth.uid() -- Users can always see their own profile
  );

-- 10. Update existing RLS policies to work with new approval system
-- (Note: This assumes existing policies exist and may need adjustment)

-- 11. Comment on new columns
COMMENT ON COLUMN users.added_by IS 'ID of the user who created this user account';
COMMENT ON COLUMN users.added_time IS 'Timestamp when the user was created';
COMMENT ON COLUMN users.approved_by IS 'ID of the director who approved this user';
COMMENT ON COLUMN users.approved_time IS 'Timestamp when the user was approved';
COMMENT ON COLUMN users.approval_status IS 'Approval status: pending, approved, or rejected';

-- Migration completed successfully
SELECT 'User approval workflow migration completed successfully!' as result;