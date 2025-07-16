# Supabase Setup Guide for Srisparks Workforce Management App

## Prerequisites
1. A Supabase account (sign up at https://supabase.com)
2. A new Supabase project created

## Step 1: Database Setup

### 1.1 Run the Main Setup Script
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor** in the left sidebar
3. Copy the entire content from `supabase_setup.sql` file
4. Paste it into a new SQL query in the editor
5. Click **Run** to execute the script

This will create:
- All necessary tables with proper relationships
- Row Level Security (RLS) policies
- Indexes for performance optimization
- Utility functions
- Sample data

### 1.2 Verify Tables Creation
After running the script, go to **Database** → **Tables** to verify all tables are created:
- `users`
- `offices`
- `customers`
- `work`
- `activity_logs`

## Step 2: Authentication Setup

### 2.1 Configure Authentication
1. Go to **Authentication** → **Settings**
2. Under **Site URL**, add your app's URL (for development: `http://localhost:3000`)
3. Under **Redirect URLs**, add your app's callback URLs
4. Disable **Enable email confirmations** for development (enable in production)

### 2.2 Create Your First Director User
1. Go to **Authentication** → **Users**
2. Click **Add user**
3. Enter:
   - Email: `director@srisparks.com`
   - Password: Choose a secure password
   - Email confirmed: ✓ (checked)
4. Click **Create user**
5. Copy the User ID (UUID) from the created user

### 2.3 Add Director Profile
1. Go to **SQL Editor**
2. Run this query (replace the UUID with your actual user ID):
```sql
INSERT INTO users (id, email, full_name, role, office_id) VALUES
('YOUR_USER_ID_HERE', 'director@srisparks.com', 'System Director', 'director', '550e8400-e29b-41d4-a716-446655440000');
```

## Step 3: Edge Functions Setup (Optional - For Advanced User Creation)

**Note: Edge Functions are optional for initial setup. You can create users manually through the Supabase Dashboard or implement user creation directly in your Flutter app using the service role key (not recommended for production).**

**Alternative: Manual User Creation**
Instead of using Edge Functions, you can:
1. Create users through the Supabase Authentication dashboard
2. Add user profiles manually via SQL queries
3. Implement user creation in your Flutter app (with proper security considerations)

**Quick Start (Skip Edge Functions):**
If you want to skip Edge Functions for now and test your app:
1. Go to **Authentication** → **Users** in your Supabase dashboard
2. Manually create test users
3. Add their profiles to the users table via SQL queries
4. Test your Flutter app with these users

**If you want to set up Edge Functions:**

### 3.1 Install Supabase CLI
**Note: Global npm installation is no longer supported for Supabase CLI.**

Choose one of these methods:

**Option A: Using Scoop (Recommended for Windows)**
```powershell
# Install Scoop if you don't have it
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Install Supabase CLI
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

**Option B: Using Chocolatey**
```powershell
# Install Chocolatey if you don't have it (run as Administrator)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Supabase CLI
choco install supabase
```

**Option C: Direct Download**
1. Go to https://github.com/supabase/cli/releases
2. Download the Windows binary for your architecture
3. Add it to your PATH

**Option D: Using npx (No installation required)**
```bash
# Use npx to run Supabase CLI without installing
npx supabase@latest --help
```

### 3.2 Login to Supabase
```bash
supabase login
```

**If using npx:**
```bash
npx supabase@latest login
```

### 3.3 Initialize Supabase in Your Project
```bash
cd your-project-directory
supabase init
```

**If using npx:**
```bash
cd your-project-directory
npx supabase@latest init
```

### 3.4 Deploy Edge Functions
1. Copy the `supabase_functions` folder to your project's `supabase/functions/` directory
2. Deploy the function:
```bash
supabase functions deploy create-user
```

**If using npx:**
```bash
npx supabase@latest functions deploy create-user
```

### 3.5 Set Environment Variables
In your Supabase project dashboard, go to **Settings** → **API** and note:
- Project URL
- `anon` public key
- `service_role` secret key (for Edge Functions)

## Step 4: Configure Your Flutter App

### 4.1 Update app_config.dart
Update your `lib/config/app_config.dart` with your Supabase credentials:

```dart
class AppConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  // ... rest of your config
}
```

### 4.2 Test the Connection
1. Run your Flutter app
2. Try to log in with your director credentials
3. Verify you can access the director dashboard

## Step 5: Row Level Security (RLS) Verification

### 5.1 Test RLS Policies
1. Create a test manager user through your app
2. Log in as the manager
3. Verify the manager can only see users in their office
4. Test work assignment and visibility

### 5.2 Common RLS Issues
If you encounter permission errors:
1. Check that RLS is enabled on all tables
2. Verify your policies are correctly written
3. Use the **SQL Editor** to test policies manually

## Step 6: Production Considerations

### 6.1 Security Checklist
- [ ] Enable email confirmations in production
- [ ] Set up proper redirect URLs
- [ ] Review and test all RLS policies
- [ ] Enable SSL/TLS for all connections
- [ ] Set up proper backup schedules

### 6.2 Performance Optimization
- [ ] Monitor slow queries in **Database** → **Logs**
- [ ] Add additional indexes if needed
- [ ] Set up connection pooling if required
- [ ] Monitor database size and usage

## Step 7: Monitoring and Maintenance

### 7.1 Set Up Monitoring
1. Go to **Settings** → **Billing** to monitor usage
2. Set up alerts for API usage, database size, and bandwidth
3. Monitor logs in **Database** → **Logs**

### 7.2 Regular Maintenance
- Review and update RLS policies as needed
- Monitor and optimize database performance
- Update indexes based on query patterns
- Regular backups and disaster recovery testing

## Troubleshooting

### Common Issues

1. **Permission Denied Errors**
   - Check RLS policies are correctly configured
   - Verify user has correct role and office assignment

2. **User Creation Fails**
   - Ensure Edge Function is deployed correctly
   - Check environment variables are set
   - Verify user has permission to create users

3. **Authentication Issues**
   - Verify Supabase URL and keys are correct
   - Check network connectivity
   - Ensure authentication is properly configured

4. **Database Connection Issues**
   - Check Supabase project status
   - Verify network connectivity
   - Check if you've exceeded rate limits

### Getting Help
- Supabase Documentation: https://supabase.com/docs
- Supabase Community: https://github.com/supabase/supabase/discussions
- Flutter + Supabase Guide: https://supabase.com/docs/guides/getting-started/tutorials/with-flutter

## Testing Data

Use these test scenarios to verify your setup:

1. **Director Login**: Should see all offices, users, and work
2. **Manager Login**: Should see only their office data
3. **Lead Login**: Should see work assigned to them and their team
4. **Employee Login**: Should see only their assigned work

## Next Steps

After completing this setup:
1. Test all user flows in your Flutter app
2. Implement proper error handling
3. Add data validation
4. Set up proper logging and monitoring
5. Plan for scalability and performance optimization
