# Installation Management Database Setup

This docu4. **"Could not find the 'customer_id' column of 'installation_work_items'" error (PGRST204)**
   - Code trying to query work_items by customer_id instead of project_id
   - This is fixed in the latest code - work_items are now queried by project_id
   - Run `database/migrations/comprehensive_installation_fix.sql` to verify all schemas
   
5. **"column 'customer_name' does not exist" error (42703)**
   - Table created with old schema missing required columns
   - **Option A (Recommended)**: Run `database/migrations/comprehensive_installation_fix.sql`
   - **Option B (Data Loss)**: Run `database/migrations/recreate_installation_tables.sql`
   
6. **Permission denied errors**rovides instructions for setting up the database tables required for the Installation Management System.

## 🚨 **Quick Fix for Column Errors**

If you're getting `column "customer_name" does not exist` errors:

1. **Open Supabase Dashboard → SQL Editor**
2. **Run this script**: `database/migrations/fix_installation_projects_columns.sql`
3. **Verify**: The script will show what columns were added

## 🗄️ Database Tables

The installation management system requires the following tables:

1. **installation_projects** - Main projects linked to customers
2. **installation_work_items** - Individual work tasks within projects  
3. **installation_material_usage** - Material tracking for work items
4. **installation_work_activities** - Activity logs for employee work tracking

## 🚀 Setup Instructions

### Option 1: Manual Setup (Recommended)

1. **Open Supabase Dashboard**
   - Go to your Supabase project dashboard
   - Navigate to the SQL Editor

2. **Run Migration Script**
   - Copy the contents of `database/migrations/create_installation_tables.sql`
   - Paste into the SQL Editor
   - Click "Run" to execute the migration

3. **Fix Column Issues (if needed)**
   - If you get column errors, run `database/migrations/fix_installation_projects_columns.sql`
   - This safely adds any missing columns to existing tables

4. **Verify Setup**
   - Check that all 4 tables are created in the Table Editor
   - Verify that Row Level Security (RLS) policies are applied

## 🚨 Troubleshooting

### Common Issues

1. **"relation does not exist" error**
   - Tables not created - run the SQL migration script
   
2. **"Could not find the 'customer_address' column" error (PGRST204)**
   - Missing columns in installation_projects table
   - Run `database/migrations/fix_installation_projects_columns.sql`
   
3. **"column 'customer_name' does not exist" error (42703)**
   - Table created with old schema missing required columns
   - **Option A (Recommended)**: Run `database/migrations/fix_installation_projects_columns.sql`
   - **Option B (Data Loss)**: Run `database/migrations/recreate_installation_tables.sql`
   
4. **Permission denied errors**
   - RLS policies not set up correctly - check user roles
   - **Option B (Data Loss)**: Run `database/migrations/recreate_installation_tables.sql`
   
5. **Permission denied errors**agement System.

## 🗄️ Database Tables

The installation management system requires the following tables:

1. **installation_projects** - Main projects linked to customers
2. **installation_work_items** - Individual work tasks within projects  
3. **installation_material_usage** - Material tracking for work items
4. **installation_work_activities** - Activity logs for employee work tracking

## 🚀 Setup Instructions

### Option 1: Manual Setup (Recommended)

1. **Open Supabase Dashboard**
   - Go to your Supabase project dashboard
   - Navigate to the SQL Editor

2. **Run Migration Script**
   - Copy the contents of `database/migrations/create_installation_tables.sql`
   - Paste into the SQL Editor
   - Click "Run" to execute the migration

3. **Update Existing Tables (if needed)**
   - If you already created the tables and are getting column errors:
   - Run `database/migrations/update_installation_projects_table.sql`
   - This adds missing columns: customer_name, customer_address, site_latitude, site_longitude

4. **Verify Setup**
   - Check that all 4 tables are created in the Table Editor
   - Verify that Row Level Security (RLS) policies are applied

### Option 2: Using Flutter App (For Testing)

```dart
import 'package:your_app/services/database_migration_service.dart';

// In your app initialization or admin screen
final migrationService = DatabaseMigrationService();

// Verify tables exist
bool tablesExist = await migrationService.verifyInstallationTables();

if (!tablesExist) {
  print('⚠️ Installation tables not found. Please run the SQL migration manually.');
}

// Create sample data for testing (optional)
await migrationService.createSampleInstallationProject(customerId);
```

## 📋 Table Schemas

### installation_projects
- **id**: UUID (Primary Key)
- **customer_id**: UUID (Foreign Key to customers)
- **status**: pending | in_progress | completed | on_hold
- **assigned_manager_id**: UUID (Foreign Key to users)
- **start_date, target_completion_date, actual_completion_date**: Dates
- **total_work_items, completed_work_items**: Integer counters
- **notes**: Text field for project notes

### installation_work_items
- **id**: UUID (Primary Key)
- **project_id**: UUID (Foreign Key to installation_projects)
- **work_type**: structure_work | panels | inverter_wiring | earthing | lightning_arrestor
- **title, description**: Text fields
- **status**: not_started | assigned | in_progress | verification_pending | completed | on_hold
- **priority**: low | medium | high | urgent
- **estimated_hours, actual_hours**: Decimal fields
- **lead_employee_id**: UUID (Foreign Key to users)
- **team_member_ids**: JSONB array of user IDs
- **location_lat, location_lng**: GPS coordinates
- **location_radius**: Allowed work radius in meters (default 100m)
- **required_materials**: JSONB object with material requirements

### installation_material_usage
- **id**: UUID (Primary Key)
- **work_item_id**: UUID (Foreign Key to installation_work_items)
- **material_name**: String
- **required_quantity, used_quantity, variance_quantity**: Decimal amounts
- **unit**: String (pieces, meters, bags, etc.)
- **cost_per_unit, total_cost**: Decimal costs
- **supplier**: String
- **recorded_by, verified_by**: UUID (Foreign Keys to users)

### installation_work_activities
- **id**: UUID (Primary Key)
- **work_item_id**: UUID (Foreign Key to installation_work_items)
- **employee_id**: UUID (Foreign Key to users)
- **activity_type**: start_work | stop_work | break_start | break_end | location_update | material_usage | status_update
- **timestamp**: Timestamp of activity
- **location_lat, location_lng, location_accuracy**: GPS data
- **is_within_site**: Boolean flag for location verification
- **distance_from_site**: Distance in meters
- **metadata**: JSONB for additional activity data

## 🔐 Security Features

### Row Level Security (RLS)
- All tables have RLS enabled
- Users can only see data from their office
- Managers and Directors have broader permissions
- Employees can only update their assigned work items

### Permissions
- **Directors**: Full access to all installation data
- **Managers**: Can create projects and assign work items
- **Employees**: Can view assigned work and record activities
- **Leads**: Can verify team work and update work item status

## 📈 Performance Optimizations

### Indexes Created
- Customer ID lookups
- Status filtering
- Employee assignments
- Work type categorization
- Activity timestamps

### Triggers
- Auto-update timestamps on record changes
- Automatic work item counters on project updates

## 🧪 Testing

After running the migration, you can:

1. **Verify Tables**: Use the `DatabaseMigrationService.verifyInstallationTables()` method
2. **Create Sample Data**: Use the `createSampleInstallationProject()` method
3. **Test Permissions**: Ensure RLS policies work correctly for different user roles

## 🚨 Troubleshooting

### Common Issues

1. **"relation does not exist" error**
   - Tables not created - run the SQL migration script
   
2. **"Could not find the 'customer_address' column" error (PGRST204)**
   - Missing columns in installation_projects table
   - Run `database/migrations/update_installation_projects_table.sql`
   - Or drop and recreate tables with the updated schema
   
3. **Permission denied errors**
   - RLS policies not set up correctly - check user roles
   
3. **Foreign key constraint violations**
   - Ensure referenced users and customers exist in the database

### Support

If you encounter issues:
1. Check the Supabase logs in the dashboard
2. Verify user authentication and roles
3. Ensure all prerequisite tables (users, customers) exist
4. Test with a database administrator role first

## 📝 Migration Log

- **2025-09-03**: Initial installation management tables created
- **Features**: Team tracking, location verification, material usage, approval workflows
- **Security**: Full RLS implementation with role-based access
- **Performance**: Optimized indexes for common queries
