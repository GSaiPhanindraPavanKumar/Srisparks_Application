# Stock Management Setup Guide

## Quick Setup Steps

### 1. Database Setup
First, you need to run the stock management database schema:

1. Go to your **Supabase project dashboard**
2. Navigate to **SQL Editor**
3. Copy the content from `stock_management_schema.sql`
4. Paste and run the SQL script

This will create the following tables:
- `stock_items` - Master stock item catalog
- `stock_inventory` - Current stock levels per office
- `stock_movements` - Audit trail of all stock transactions
- `work_stock_requirements` - Links work orders to required stock

### 2. Access Stock Management

The stock management screen has been added to both Manager and Director navigation:

#### For Managers:
1. Login as a Manager
2. Open the sidebar menu
3. Click **"Stock Management"**

#### For Directors:
1. Login as a Director
2. Open the sidebar menu
3. Click **"Stock Management"**

### 3. Fixed Issues

✅ **Fixed the Supabase query error** in `stock_service.dart`
✅ **Added navigation routes** for stock management
✅ **Updated sidebars** for Manager and Director roles
✅ **Role-based access** - Managers see their office stock, Directors see all

### 4. Navigation Path

```
Manager Dashboard → Sidebar → Stock Management
Director Dashboard → Sidebar → Stock Management
```

### 5. Sample Usage

Once you access the Stock Management screen, you can:

- **View inventory levels** for your office
- **See stock status** (Normal/Low Stock/Out of Stock)
- **Filter and search** stock items
- **Add/Update stock** quantities
- **View stock movements** history
- **Transfer stock** between offices (Directors only)

### 6. Role Permissions

**Directors**:
- View stock from ALL offices
- Transfer stock between offices
- Create stock items for any office
- View consolidated reports

**Managers**: 
- View stock from their assigned office only
- Create/edit stock items in their office
- Record stock movements (in/out/adjustments)
- Request transfers (if implemented)

### 7. Database Verification

To verify the database setup worked correctly, check these tables exist in Supabase:

```sql
-- Check if tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE 'stock_%';
```

You should see:
- stock_items
- stock_inventory  
- stock_movements
- work_stock_requirements

### 8. Test Data

You can add sample stock items through the UI or insert test data:

```sql
-- Sample stock item
INSERT INTO stock_items (name, category, unit, cost_price, min_stock_level, max_stock_level, office_id)
VALUES ('Cable - Cat6', 'Networking', 'meters', 2.50, 100, 1000, 'your-office-id');
```

### 9. Troubleshooting

**If you get navigation errors:**
- Make sure you've saved all the updated files
- Restart the Flutter app (`flutter run`)

**If you get database errors:**
- Verify the SQL schema ran successfully
- Check Supabase table permissions
- Ensure RLS policies are active

**If stock data doesn't show:**
- Add some test stock items first
- Verify your user has an assigned office_id
- Check if stock_inventory records exist

### 10. Next Steps

After basic setup:
1. **Add stock items** for your offices
2. **Record initial stock quantities**
3. **Set up stock categories** for better organization
4. **Train users** on stock management workflows
5. **Integrate with work orders** for automatic stock allocation

The stock management system is now ready to use! 🚀
