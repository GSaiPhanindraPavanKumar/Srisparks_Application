# Quick Setup Guide - Attendance Updates

## Step 1: Run Database Migration

Open Supabase SQL Editor and run:

```sql
-- Copy and paste the entire contents of attendance_updates_migration.sql
```

Or use Supabase CLI:
```bash
supabase db push
```

## Step 2: Verify Database Changes

Run this query to verify:
```sql
-- Check if attendance_updates table exists
SELECT * FROM information_schema.tables 
WHERE table_name = 'attendance_updates';

-- Check if new columns exist in attendance table
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'attendance' 
AND column_name IN ('check_in_update', 'check_out_update', 'check_in_latitude', 'check_in_longitude');

-- Check if trigger exists
SELECT trigger_name 
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_auto_checkout_previous';
```

All queries should return results.

## Step 3: Update Flutter App

```bash
# No additional dependencies needed
# Just run the app
flutter run
```

## Step 4: Test the Features

### Test 1: Check-In with Update
1. Open app → Attendance
2. Tap "Check In"
3. Enter update: "Starting work today"
4. Verify check-in successful

### Test 2: Add Multiple Updates
1. While checked in, tap "Add Status Update"
2. Enter: "Client meeting"
3. Wait a few minutes
4. Tap "Add Status Update" again
5. Enter: "Site visit"
6. Verify both updates appear with different times

### Test 3: Auto-Checkout Test
1. Check in today but DON'T check out
2. **Tomorrow**, try to check in
3. Should work without error
4. Check database - yesterday's record should be auto-checked-out at 6 PM

```sql
-- Verify auto-checkout worked
SELECT * FROM attendance 
WHERE user_id = 'your-user-id' 
AND attendance_date = CURRENT_DATE - 1;
-- Should show status='checked_out' and checkout_time around 18:00
```

## Step 5: Grant Permissions (if needed)

If users can't add updates, run:

```sql
-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON attendance TO authenticated;
GRANT SELECT, INSERT ON attendance_updates TO authenticated;
```

## Common Issues

### "No active check-in found"
- User must check in first before adding updates
- Solution: Tap "Check In" button first

### "Location services disabled"
- User needs to enable GPS
- Solution: Settings → Location → Enable

### "You are already checked in today"
- Old issue - should be fixed by auto-checkout trigger
- If still happens, manually checkout previous day:
```sql
UPDATE attendance 
SET status = 'checked_out',
    check_out_time = NOW()
WHERE user_id = 'problem-user-id' 
AND status = 'checked_in'
AND attendance_date < CURRENT_DATE;
```

## Quick Reference

### User Actions:
- **Check In** → Records start time + location + optional update
- **Add Update** → Records current time + location + update text (anytime while checked in)
- **Check Out** → Records end time + location + optional update

### Data Captured Per Update:
- `update_text` - What user is doing
- `update_time` - Exact timestamp
- `latitude` - GPS coordinate
- `longitude` - GPS coordinate

### Database Tables:
- `attendance` - Main check-in/check-out records
- `attendance_updates` - Multiple updates throughout the day

---

✅ Setup complete! Users can now add updates throughout their workday with automatic location tracking.
