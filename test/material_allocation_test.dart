// Test script to verify material allocation functionality
// Run this in Dart console or create a test file

import 'package:flutter_test/flutter_test.dart';
import '../lib/services/material_allocation_service.dart';
import '../lib/models/material_allocation_model.dart';
import '../lib/models/material_allocation_item_model.dart';

void main() {
  group('Material Allocation Tests', () {
    test('Create and manage material allocation', () async {
      // Note: These tests would need actual Supabase setup and test data
      // This is a template showing how to test the allocation system

      // Test 1: Create allocation
      final allocation = await MaterialAllocationService.createAllocation(
        customerId: 'test-customer-id',
        officeId: 'test-office-id',
        allocatedById: 'test-user-id',
        notes: 'Test allocation',
      );

      expect(allocation.id, isNotNull);
      expect(allocation.status, equals('draft'));
      expect(allocation.customerId, equals('test-customer-id'));

      // Test 2: Add allocation items
      final item1 = await MaterialAllocationService.addAllocationItem(
        materialAllocationId: allocation.id!,
        stockItemId: 'test-stock-item-1',
        requiredQuantity: 10,
        allocatedQuantity: 5,
      );

      expect(item1.requiredQuantity, equals(10));
      expect(item1.allocatedQuantity, equals(5));
      expect(item1.pendingQuantity, equals(5));

      // Test 3: Update allocation item
      final updatedItem = await MaterialAllocationService.updateAllocationItem(
        itemId: item1.id!,
        allocatedQuantity: 10,
      );

      expect(updatedItem.allocatedQuantity, equals(10));
      expect(updatedItem.isFullyAllocated, isTrue);

      // Test 4: Confirm allocation
      final confirmedAllocation =
          await MaterialAllocationService.confirmAllocation(allocation.id!);

      expect(confirmedAllocation.status, equals('confirmed'));
      expect(confirmedAllocation.isConfirmed, isTrue);

      // Test 5: Get allocation with items
      final fullAllocation = await MaterialAllocationService.getAllocation(
        allocation.id!,
      );

      expect(fullAllocation.items, isNotEmpty);
      expect(fullAllocation.totalRequiredItems, equals(10));
      expect(fullAllocation.totalAllocatedItems, equals(10));
      expect(fullAllocation.allocationCompletionPercentage, equals(100.0));

      print('All material allocation tests passed!');
    });

    test('Allocation statistics and summary', () async {
      // Test allocation stats functionality
      final stats = await MaterialAllocationService.getAllocationStats(
        officeId: 'test-office-id',
      );

      expect(stats['total_allocations'], isA<int>());
      expect(stats['total_items'], isA<int>());
      expect(stats['status_counts'], isA<Map>());

      print('Allocation statistics test passed!');
    });

    test('Material allocation item calculations', () {
      // Test model calculations
      final item = MaterialAllocationItemModel(
        materialAllocationId: 'test-allocation',
        stockItemId: 'test-item',
        requiredQuantity: 20,
        allocatedQuantity: 15,
        deliveredQuantity: 10,
        availableStock: 25,
        unitPrice: 100.0,
      );

      expect(item.pendingQuantity, equals(5));
      expect(item.pendingDelivery, equals(5));
      expect(item.allocationPercentage, equals(75.0));
      expect(item.deliveryPercentage, equals(66.66666666666667));
      expect(item.totalRequiredValue, equals(2000.0));
      expect(item.totalAllocatedValue, equals(1500.0));
      expect(item.totalDeliveredValue, equals(1000.0));
      expect(item.hasEnoughStock, isTrue);
      expect(item.shortfallQuantity, equals(0));

      print('Material allocation item calculations test passed!');
    });

    test('Allocation model aggregations', () {
      // Test allocation model with items
      final items = [
        MaterialAllocationItemModel(
          materialAllocationId: 'test-allocation',
          stockItemId: 'item-1',
          requiredQuantity: 10,
          allocatedQuantity: 10,
          deliveredQuantity: 8,
        ),
        MaterialAllocationItemModel(
          materialAllocationId: 'test-allocation',
          stockItemId: 'item-2',
          requiredQuantity: 20,
          allocatedQuantity: 15,
          deliveredQuantity: 10,
        ),
      ];

      final allocation = MaterialAllocationModel(
        customerId: 'test-customer',
        officeId: 'test-office',
        allocatedById: 'test-user',
        status: 'confirmed',
        items: items,
      );

      expect(allocation.totalRequiredItems, equals(30));
      expect(allocation.totalAllocatedItems, equals(25));
      expect(allocation.totalDeliveredItems, equals(18));
      expect(
        allocation.allocationCompletionPercentage,
        equals(83.33333333333334),
      );
      expect(allocation.deliveryCompletionPercentage, equals(72.0));

      print('Allocation model aggregations test passed!');
    });
  });
}

// Helper functions for testing with real data
class MaterialAllocationTestHelper {
  static Future<String> createTestCustomer() async {
    // This would create a test customer in the database
    // Return the customer ID
    return 'test-customer-id';
  }

  static Future<String> createTestOffice() async {
    // This would create a test office in the database
    // Return the office ID
    return 'test-office-id';
  }

  static Future<String> createTestStockItem({
    required String officeId,
    required String itemName,
    required int currentStock,
  }) async {
    // This would create a test stock item in the database
    // Return the stock item ID
    return 'test-stock-item-id';
  }

  static Future<void> cleanupTestData() async {
    // This would clean up all test data from the database
    // Important for maintaining clean test state
  }
}

// Sample usage demonstration
void demonstrateAllocationWorkflow() async {
  print('=== Material Allocation Workflow Demonstration ===');

  try {
    // 1. Create allocation
    print('1. Creating allocation...');
    final allocation = await MaterialAllocationService.createAllocation(
      customerId: 'customer-123',
      officeId: 'office-456',
      allocatedById: 'user-789',
      notes: 'Solar panel installation for residential customer',
    );
    print('✓ Allocation created: ${allocation.id}');

    // 2. Add items
    print('2. Adding allocation items...');
    final solarPanels = await MaterialAllocationService.addAllocationItem(
      materialAllocationId: allocation.id!,
      stockItemId: 'solar-panel-540w',
      requiredQuantity: 20,
      allocatedQuantity: 0,
    );

    final inverter = await MaterialAllocationService.addAllocationItem(
      materialAllocationId: allocation.id!,
      stockItemId: 'inverter-5kw',
      requiredQuantity: 1,
      allocatedQuantity: 0,
    );
    print('✓ Items added: Solar panels (20), Inverter (1)');

    // 3. Update allocations based on stock availability
    print('3. Allocating available stock...');
    await MaterialAllocationService.updateAllocationItem(
      itemId: solarPanels.id!,
      allocatedQuantity: 18, // 2 short
    );

    await MaterialAllocationService.updateAllocationItem(
      itemId: inverter.id!,
      allocatedQuantity: 1, // Full allocation
    );
    print('✓ Stock allocated: Solar panels (18/20), Inverter (1/1)');

    // 4. Confirm allocation
    print('4. Confirming allocation...');
    final confirmedAllocation =
        await MaterialAllocationService.confirmAllocation(allocation.id!);
    print('✓ Allocation confirmed with status: ${confirmedAllocation.status}');

    // 5. Check final status
    print('5. Getting final allocation details...');
    final finalAllocation = await MaterialAllocationService.getAllocation(
      allocation.id!,
    );

    print('✓ Final allocation summary:');
    print('  - Total required: ${finalAllocation.totalRequiredItems}');
    print('  - Total allocated: ${finalAllocation.totalAllocatedItems}');
    print(
      '  - Completion: ${finalAllocation.allocationCompletionPercentage.toStringAsFixed(1)}%',
    );
    print('  - Status: ${finalAllocation.statusDisplayName}');

    print('\n=== Workflow completed successfully! ===');
  } catch (e) {
    print('❌ Error in workflow: $e');
  }
}
