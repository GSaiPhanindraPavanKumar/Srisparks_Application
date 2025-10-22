# Database Duplication Guide

## Current Production Setup
- **URL**: Your current Supabase URL from app_config.dart
- **Database**: Production database with live data

## Steps to Duplicate Database:

### Option 1: Manual Export/Import (Safest)

1. **Export Production Schema:**
   - Go to Supabase Dashboard > SQL Editor
   - Run this query to get all tables:
   ```sql
   SELECT table_name 
   FROM information_schema.tables 
   WHERE table_schema = 'public';
   ```

2. **Export each table structure:**
   ```sql
   -- For each table, get the CREATE statement
   SELECT 
       'CREATE TABLE ' || schemaname||'.'||tablename||' (' ||
       array_to_string(
           array_agg(
               column_name||' '|| type||' '||not_null
           )
           , ', '
       )||' );'
   FROM (
       SELECT 
           schemaname, tablename, 
           attname AS column_name,
           pg_catalog.format_type(atttypid, atttypmod) as type,
           CASE WHEN attnotnull = false THEN 'NULL' ELSE 'NOT NULL' END as not_null 
       FROM pg_attribute 
       JOIN pg_class ON pg_class.oid = pg_attribute.attrelid 
       JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace 
       WHERE pg_attribute.attnum > 0 
       AND nspname = 'public'
   ) as tabledefinition 
   GROUP BY schemaname, tablename;
   ```

### Option 2: Using pg_dump (Advanced)

If you have access to database connection string:
```bash
pg_dump "postgresql://[user]:[password]@[host]:[port]/[database]" > schema.sql
```

### Option 3: Create New Supabase Project

1. **Create New Project:**
   - Go to https://supabase.com/dashboard
   - Click "New Project"
   - Name: "SriSparks-Development"
   - Choose same region as production

2. **Copy Configuration:**
   - Update app_config.dart with new URLs
   - Use environment variables to switch between prod/dev

## Configuration Update Needed:

Update `lib/config/app_config.dart` to support multiple environments:

```dart
class AppConfig {
  static const String environment = String.fromEnvironment('ENV', defaultValue: 'development');
  
  // Production URLs (current)
  static const String _prodSupabaseUrl = 'your-current-url';
  static const String _prodSupabaseAnonKey = 'your-current-key';
  
  // Development URLs (new)
  static const String _devSupabaseUrl = 'new-development-url';
  static const String _devSupabaseAnonKey = 'new-development-key';
  
  static String get supabaseUrl => 
    environment == 'production' ? _prodSupabaseUrl : _devSupabaseUrl;
    
  static String get supabaseAnonKey => 
    environment == 'production' ? _prodSupabaseAnonKey : _devSupabaseAnonKey;
}
```

## Recommended Approach:
1. Create new Supabase project for development
2. Export your current database schema (I can help generate this)
3. Import schema to new project
4. Update app configuration for environment switching
5. Test with development database