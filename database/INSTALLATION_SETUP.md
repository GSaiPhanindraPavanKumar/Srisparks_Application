# Installation System Database Setup

## 🚨 Database Tables Missing Error Fix

You're seeing the `404 Not Found` error for `installation_projects` because the database tables haven't been created yet.

## 📋 Setup Instructions

### Step 1: Run the Migration Script
Execute the SQL migration script in your Supabase dashboard:

1. **Open Supabase Dashboard**
   - Go to https://supabase.com/dashboard
   - Select your project: `hgklojjpvhugwplylofg`

2. **Navigate to SQL Editor**
   - Click on "SQL Editor" in the left sidebar
   - Click "New Query"

3. **Execute Migration Script**
   - Copy the entire content from `database/installation_system_migration.sql`
   - Paste it into the SQL editor
   - Click "Run" to execute

### Step 2: Verify Tables Created
After running the migration, verify these tables exist:

- ✅ `installation_projects`
- ✅ `installation_work_items` 
- ✅ `installation_employee_assignments`
- ✅ `installation_work_sessions`
- ✅ `installation_location_logs`

### Step 3: Test the Installation Assignment
1. **Restart Flutter App**
   ```bash
   flutter hot restart
   ```

2. **Test Assignment Flow**
   - Go to Director Dashboard
   - Find a customer in "Installation" phase
   - Click "Assign Installation"
   - Should open the assignment dialog

## 🎯 What the Migration Creates

### Tables Structure:
- **installation_projects**: Main project records for each customer
- **installation_work_items**: Individual work tasks (Structure, Panels, Wiring, etc.)
- **installation_employee_assignments**: Many-to-many employee assignments
- **installation_work_sessions**: Time tracking and GPS verification
- **installation_location_logs**: Periodic location checks

### Security:
- **RLS Policies**: Role-based access (Director > Manager > Employee)
- **Data Isolation**: Employees only see their assignments
- **Office-based Access**: Managers see only their office's installations

### Features:
- **GPS Tracking**: Verify employees are on-site
- **Progress Tracking**: Track completion percentage for each work type
- **Photo Documentation**: Store completion photos
- **Time Logging**: Track actual vs estimated hours

## 🔧 Troubleshooting

### If migration fails:
1. **Check permissions**: Ensure you have admin access to Supabase
2. **Run in parts**: Execute each table creation separately
3. **Check constraints**: Some constraints might need existing data

### If RLS issues occur:
1. **Verify user roles**: Check `users` table has correct role values
2. **Check JWT claims**: Ensure auth.jwt() returns expected role
3. **Test permissions**: Use different user roles to verify access

## 📊 Testing Queries

After migration, test with these queries:

```sql
-- Check installation projects
SELECT * FROM installation_projects LIMIT 5;

-- Check work items
SELECT * FROM installation_work_items LIMIT 5;

-- Check project overview
SELECT * FROM installation_project_overview LIMIT 5;
```

## 🎉 Next Steps

Once tables are created:
1. **Test Assignment**: Create installation assignments from director dashboard
2. **Employee Access**: Test employee can see their assignments
3. **GPS Features**: Test location verification (requires mobile app)
4. **Progress Tracking**: Update work item statuses and track progress

---
**Note**: This migration is safe to run multiple times - it uses `IF NOT EXISTS` clauses.
