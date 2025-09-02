# Attendance System Database Setup

## Instructions for setting up the attendance database:

1. **Run the attendance_schema.sql in your Supabase SQL Editor:**
   - Open your Supabase project dashboard
   - Go to SQL Editor
   - Copy and paste the contents of `database/attendance_schema.sql`
   - Run the script to create the attendance table and all required functions/triggers

2. **The schema includes:**
   - `attendance` table with required fields (check-in/out times, coordinates, date)
   - Row Level Security (RLS) policies for proper data access control
   - Automatic triggers for status updates
   - Indexes for optimal query performance
   - Prevention of multiple active check-ins

3. **Required Permissions:**
   - Location permissions are already configured in AndroidManifest.xml
   - iOS permissions will need to be added to Info.plist if targeting iOS

4. **Dependencies:**
   - All required packages are already in pubspec.yaml:
     - `geolocator: ^10.1.0` for GPS location
     - `permission_handler: ^11.2.0` for permissions

## Usage:

After running the database schema, the attendance system will be available to:
- **Managers**: Can view their own attendance via sidebar navigation
- **Employees**: Can view their own attendance via sidebar navigation
- **Directors**: Can view their own attendance (may be extended later for office-wide reporting)

## Features:

- **Location-based check-in/out**: Records GPS coordinates (latitude/longitude)
- **Date tracking**: Records attendance date for proper organization
- **Automatic status updates**: Updates status when checking out
- **Attendance history**: View past attendance records with details
- **Weekly summaries**: Overview of work patterns and statistics
- **Real-time status**: Shows current check-in status and duration calculation
