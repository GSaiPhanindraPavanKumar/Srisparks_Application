# Development Environment Setup Guide

This guide will help you set up a separate development database to avoid affecting your production data.

## Step 1: Create New Supabase Project for Development

### Option A: Using Supabase Dashboard (Recommended)
1. Go to https://supabase.com/dashboard
2. Click "New Project"
3. Choose your organization
4. Name: `srisparks-dev` (or similar)
5. Region: Choose same as production for consistency
6. Database Password: Create a strong password
7. Click "Create new project"

### Option B: Using CLI (Alternative)
```bash
npx supabase projects create srisparks-dev --org-id your-org-id
```

## Step 2: Set Up Database Schema

### Copy the schema to your new project:
1. Open the new project dashboard
2. Go to SQL Editor
3. Copy and paste the entire content from `database_schema_complete.sql`
4. Click "Run" to execute the schema

### Verify the setup:
```sql
-- Check if all tables were created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- Verify the main tables
SELECT COUNT(*) as offices_count FROM offices;
SELECT COUNT(*) as users_count FROM users;
SELECT COUNT(*) as customers_count FROM customers;
```

## Step 3: Update App Configuration

### Get your new project credentials:
1. In Supabase dashboard → Settings → API
2. Copy the Project URL and anon public key

### Update the development configuration:
1. Replace `app_config.dart` with `app_config_new.dart`
2. Update the development URLs and keys:

```dart
// In app_config_new.dart, update these values:
case 'development':
  return 'https://your-new-dev-project.supabase.co'; // Your dev URL

case 'development':
  return 'your-dev-anon-key-here'; // Your dev anon key
```

## Step 4: Environment-Based Running

### For Development (points to dev database):
```bash
flutter run --dart-define=ENVIRONMENT=development
```

### For Production (points to live database):
```bash
flutter run --dart-define=ENVIRONMENT=production
```

### For Building with Environment:
```bash
# Development build
flutter build web --dart-define=ENVIRONMENT=development

# Production build  
flutter build web --dart-define=ENVIRONMENT=production

# Android APK for development
flutter build apk --dart-define=ENVIRONMENT=development
```

## Step 5: Add Sample Data (Optional)

You can add some test data to your development database:

```sql
-- Insert a test office
INSERT INTO offices (name, address, city, state) 
VALUES ('Test Office', '123 Test St', 'Test City', 'Test State');

-- Insert a test director user
INSERT INTO users (email, full_name, role, status, approval_status, office_id)
VALUES ('dev@test.com', 'Dev Director', 'director', 'active', 'approved', 
        (SELECT id FROM offices WHERE name = 'Test Office'));
```

## Step 6: Verify Setup

### Check environment detection:
```dart
// Add this to your main.dart temporarily
import 'config/app_config_new.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Print configuration for verification
  AppConfig.printConfig();
  
  runApp(MyApp());
}
```

### Environment indicators in UI:
The new config includes environment badges that will show:
- 🛠️ DEV for development
- 🚧 STAGING for staging  
- Nothing for production

## Step 7: Data Migration (If Needed)

### Export from production (if you want to copy existing data):
```bash
# Using Supabase CLI
npx supabase db dump --db-url "postgresql://postgres:password@db.hgklojjpvhugwplylofg.supabase.co:5432/postgres" --data-only > production_data.sql

# Import to development
npx supabase db reset --db-url "postgresql://postgres:password@db.your-dev-project.supabase.co:5432/postgres"
psql "postgresql://postgres:password@db.your-dev-project.supabase.co:5432/postgres" < production_data.sql
```

## Benefits of This Setup

✅ **Safe Development**: Changes won't affect live users
✅ **Environment Isolation**: Clear separation between dev/staging/prod
✅ **Easy Switching**: Change environment with single flag
✅ **Visual Indicators**: Know which environment you're in
✅ **Feature Flags**: Enable beta features only in dev/staging
✅ **Proper Logging**: Different log levels per environment

## Quick Commands Reference

```bash
# Start development mode
flutter run --dart-define=ENVIRONMENT=development

# Start production mode (default)
flutter run --dart-define=ENVIRONMENT=production

# Build for different environments
flutter build web --dart-define=ENVIRONMENT=development
flutter build apk --dart-define=ENVIRONMENT=production

# Check Supabase projects
npx supabase projects list
```

## Security Notes

⚠️ **Important**: 
- Never commit real API keys to version control
- Use environment variables for sensitive data
- Keep development and production credentials separate
- Regularly rotate API keys
- Use Row Level Security (RLS) in both environments

This setup ensures you can develop safely without affecting your live application!