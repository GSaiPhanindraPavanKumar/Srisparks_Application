# Stock Management System - Office Integration

## Overview

The Stock Management System is designed to seamlessly integrate with your existing Srisparks Workforce Management App, providing office-specific inventory control while maintaining the same role-based access patterns.

## How Stock Links to Offices

### 1. Office-Centric Design
- **Every stock item belongs to a specific office** (`office_id` in `stock_items`)
- **Stock inventory is tracked per office** (`office_id` in `stock_inventory`)
- **Stock movements are office-specific** (`office_id` in `stock_movements`)
- **Users can only see stock from their assigned office** (except Directors)

### 2. Role-Based Stock Access

#### Director (Full Access)
```dart
// Directors can:
- View stock from ALL offices
- Create/edit stock items in any office
- Transfer stock between offices
- View consolidated stock reports
- Access stock analytics across all locations
```

#### Manager (Office-Level Access)
```dart
// Managers can:
- View stock from their assigned office only
- Create/edit stock items in their office
- Manage stock movements (in/out/adjustments)
- Request stock transfers from other offices
- View office-specific stock reports
```

#### Lead (Limited Management)
```dart
// Leads can:
- View stock from their office
- Record stock usage for work orders
- Create stock movement records
- View stock levels for work planning
```

#### Employee (View Only)
```dart
// Employees can:
- View available stock for their work
- See stock requirements for assigned tasks
- Record stock usage (if permitted)
```

### 3. Stock-Work Integration

#### Work Order Stock Requirements
```dart
// When creating work orders, you can:
1. Specify required stock items and quantities
2. System checks availability in the office
3. Stock gets reserved for the work order
4. Actual usage is recorded upon work completion
5. Unused stock is returned to available inventory
```

#### Automatic Stock Allocation
```dart
WorkModel work = await workService.createWork(
  // ... other parameters
  stockRequirements: [
    StockRequirement(itemId: 'cable_id', quantity: 100),
    StockRequirement(itemId: 'connector_id', quantity: 10),
  ]
);
```

### 4. Office Stock Operations

#### Stock Transfer Between Offices
```dart
// Transfer stock from one office to another
await stockService.transferStock(
  stockItemId: 'item_id',
  fromOfficeId: 'office_1',
  toOfficeId: 'office_2',
  quantity: 50,
  reason: 'Balancing inventory',
);
```

#### Office-Specific Inventory Management
```dart
// Get stock inventory for a specific office
List<StockInventoryModel> inventory = 
  await stockService.getStockInventoryByOffice(officeId);

// Check low stock alerts for an office
List<StockInventoryModel> lowStock = 
  await stockService.getLowStockAlerts(officeId);
```

## Implementation Strategy

### Phase 1: Basic Stock Management
1. **Set up database schema** (use `stock_management_schema.sql`)
2. **Implement stock models** (StockItemModel, StockInventoryModel, etc.)
3. **Create StockService** for basic CRUD operations
4. **Build stock management screens** for each user role

### Phase 2: Work Integration
1. **Add stock requirements to work orders**
2. **Implement stock allocation/reservation system**
3. **Create work-stock tracking screens**
4. **Add stock usage recording in work completion**

### Phase 3: Advanced Features
1. **Stock transfer workflows**
2. **Automated reorder points**
3. **Stock valuation reports**
4. **Barcode scanning integration**

## Database Schema Integration

### Key Tables
```sql
-- Links stock items to offices
stock_items (office_id → offices.id)

-- Tracks inventory per office
stock_inventory (office_id → offices.id, stock_item_id → stock_items.id)

-- Audit trail of movements
stock_movements (office_id → offices.id, stock_item_id → stock_items.id)

-- Optional: Work-stock relationship
work_stock_requirements (work_id → work.id, stock_item_id → stock_items.id)
```

### Security (Row Level Security)
```sql
-- Users can only see stock from their office
-- Directors can see stock from all offices
-- Same pattern as existing user/work/customer RLS policies
```

## UI/UX Integration

### Navigation Structure
```
Director Dashboard
├── Stock Management
│   ├── All Offices Stock Overview
│   ├── Stock Transfers
│   ├── Stock Reports
│   └── Stock Analytics

Manager Dashboard
├── Stock Management
│   ├── Office Inventory
│   ├── Stock Movements
│   ├── Low Stock Alerts
│   └── Stock Requests

Employee Dashboard
├── My Work
│   ├── Work Details
│   │   ├── Required Stock
│   │   └── Stock Usage
```

### Screen Examples

#### Stock Inventory Screen
```dart
// Shows office-specific stock levels
// Color-coded status (Normal/Low/Out of Stock)
// Search and filter capabilities
// Quick actions (Add Stock, Transfer, Adjust)
```

#### Stock Movement Screen
```dart
// Record stock in/out movements
// Link to work orders
// Add reasons and reference numbers
// Photo/document attachments
```

#### Work Order Stock Screen
```dart
// Part of existing work detail screen
// Shows required vs allocated vs used stock
// Allows recording actual usage
// Alerts for insufficient stock
```

## Benefits of Office-Linked Stock

### 1. **Decentralized Management**
- Each office manages its own inventory
- Reduces complexity for managers
- Enables location-specific optimization

### 2. **Accurate Work Planning**
- Know what stock is available before assigning work
- Prevent work delays due to stock shortages
- Better cost estimation with stock costs

### 3. **Improved Accountability**
- Track who used what stock for which work
- Complete audit trail of stock movements
- Role-based access prevents unauthorized usage

### 4. **Business Intelligence**
- Office-wise stock performance
- Work-stock correlation analysis
- Inventory optimization insights
- Cost per office/work analysis

## Sample Implementation Code

### Stock Dashboard Widget
```dart
class StockDashboardWidget extends StatelessWidget {
  final String officeId;
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StockSummary>(
      future: stockService.getStockSummary(officeId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Row(
            children: [
              StockMetricCard(
                title: 'Total Items',
                value: '${snapshot.data!.totalItems}',
                icon: Icons.inventory,
              ),
              StockMetricCard(
                title: 'Low Stock',
                value: '${snapshot.data!.lowStockCount}',
                icon: Icons.warning,
                color: Colors.orange,
              ),
              StockMetricCard(
                title: 'Total Value',
                value: '₹${snapshot.data!.totalValue}',
                icon: Icons.attach_money,
              ),
            ],
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

### Work Stock Requirement Widget
```dart
class WorkStockRequirementsWidget extends StatelessWidget {
  final String workId;
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WorkStockRequirement>>(
      future: stockService.getWorkStockRequirements(workId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            children: [
              Text('Required Stock Items'),
              ...snapshot.data!.map((req) => 
                ListTile(
                  title: Text(req.stockItemName),
                  subtitle: Text('Required: ${req.requiredQuantity}'),
                  trailing: Text('Available: ${req.availableQuantity}'),
                  leading: Icon(
                    req.availableQuantity >= req.requiredQuantity 
                      ? Icons.check_circle 
                      : Icons.warning,
                    color: req.availableQuantity >= req.requiredQuantity 
                      ? Colors.green 
                      : Colors.red,
                  ),
                )
              ),
            ],
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

## Next Steps

1. **Run the database schema** to create stock tables
2. **Test the models and services** with sample data
3. **Build the UI screens** for stock management
4. **Integrate with existing work flows**
5. **Add stock requirements to work creation**
6. **Implement transfer workflows between offices**

This office-linked stock management system will provide complete inventory control while maintaining the security and organizational structure of your existing Srisparks application.
