import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../models/office_model.dart';
import '../../models/stock_item_model.dart';
import '../../services/stock_service.dart';
import '../../services/auth_service.dart';
import '../../services/simplified_material_allocation_service.dart';

class MaterialAllocationPlan extends StatefulWidget {
  final CustomerModel customer;
  final OfficeModel office;

  const MaterialAllocationPlan({
    super.key,
    required this.customer,
    required this.office,
  });

  @override
  State<MaterialAllocationPlan> createState() => _MaterialAllocationPlanState();
}

class _MaterialAllocationPlanState extends State<MaterialAllocationPlan> {
  final StockService _stockService = StockService();
  final AuthService _authService = AuthService();

  List<StockItemModel> _stockItems = [];
  Map<String, dynamic> _allocationPlan = {};
  bool _isLoading = true;

  // Manual requirements - editable by user
  Map<String, int> _manualRequirements = {};
  
  // Track if allocation has been saved
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  Future<void> _loadStockData() async {
    setState(() => _isLoading = true);

    try {
      // Load actual stock data from the office
      print('Loading stock data for office: ${widget.office.id}');

      final stockItems = await _stockService.getStockItemsByOffice(
        widget.office.id,
      );
      print('Loaded ${stockItems.length} stock items');

      _stockItems = stockItems;

      // Initialize manual requirements for all stock items FIRST
      _initializeManualRequirements();

      // Load existing allocation plan if it exists (this will override defaults)
      await _loadExistingAllocationPlan();

      // Create allocation plan based on available stock
      _createAllocationPlan();

      print('Stock data loaded successfully');
    } catch (e, stackTrace) {
      print('Error loading stock data: $e');
      print('Stack trace: $stackTrace');

      // Fallback to empty stock list to prevent crashes
      _stockItems = [];
      _initializeManualRequirements();
      _createAllocationPlan();

      _showMessage('Error loading stock data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExistingAllocationPlan() async {
    try {
      // Check if customer already has an allocation plan
      if (widget.customer.hasMaterialAllocationPlan) {
        final existingItems = widget.customer.materialAllocationItems;
        
        print('Found existing allocation plan with ${existingItems.length} items');
        
        // Load existing requirements - override any defaults
        int loadedCount = 0;
        for (final item in existingItems) {
          final stockItemId = item['stock_item_id'] as String?;
          final requiredQuantity = item['required_quantity'] as int? ?? 0;
          
          if (stockItemId != null && requiredQuantity > 0) {
            _manualRequirements[stockItemId] = requiredQuantity;
            loadedCount++;
            print('Loaded: $stockItemId -> $requiredQuantity');
          }
        }
        
        print('Successfully loaded $loadedCount requirement entries');
        
        if (mounted) {
          _showMessage('Loaded existing allocation plan with $loadedCount items');
        }
        
        // Mark as having unsaved changes if we loaded something
        if (loadedCount > 0) {
          _hasUnsavedChanges = false; // It's already saved
        }
      } else {
        print('No existing allocation plan found for customer');
      }
    } catch (e) {
      print('Error loading existing allocation plan: $e');
      if (mounted) {
        _showMessage('Warning: Could not load existing allocation plan');
      }
    }
  }

  void _initializeManualRequirements() {
    // Only initialize if not already set
    if (_manualRequirements.isEmpty) {
      _manualRequirements.clear();

      // Set default quantities for each stock item (0 initially)
      for (final item in _stockItems) {
        _manualRequirements[item.id!] = 0;
      }
    } else {
      // Ensure all current stock items have entries (in case new items were added)
      for (final item in _stockItems) {
        _manualRequirements[item.id!] ??= 0;
      }
    }
  }

  void _createAllocationPlan() {
    _allocationPlan = {};

    // Create allocation plan based on actual stock items
    for (final item in _stockItems) {
      final required = _manualRequirements[item.id!] ?? 0;

      _allocationPlan[item.id!] = {
        'item_name': item.name,
        'required': required,
        'available': item.currentStock,
        'status': item.currentStock >= required
            ? 'available'
            : item.currentStock > 0
            ? 'partial'
            : 'unavailable',
        'shortage': item.currentStock >= required
            ? 0
            : required - item.currentStock,
        'item_id': item.id,
        'unit': 'pieces', // Default unit, can be customized per item type
      };
    }
  }

  void _updateRequiredQuantity(String itemId, int newQuantity) {
    setState(() {
      _manualRequirements[itemId] = newQuantity.clamp(0, 9999);
      _hasUnsavedChanges = true;
      _createAllocationPlan(); // Refresh allocation plan
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Allocation Plan'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProjectSummary(),
                  const SizedBox(height: 20),
                  _buildMaterialRequirements(),
                  const SizedBox(height: 20),
                  _buildAllocationActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildProjectSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Customer', widget.customer.name),
            _buildSummaryRow('Office', widget.office.name),
            _buildSummaryRow('Address', widget.customer.address ?? 'N/A'),
            _buildSummaryRow(
              'System Size',
              '${widget.customer.kw ?? widget.customer.estimatedKw ?? 0} kW',
            ),
            _buildSummaryRow(
              'Project Value',
              widget.customer.amountTotal != null
                  ? '₹${widget.customer.amountTotal!.toStringAsFixed(0)}'
                  : 'N/A',
            ),
            _buildSummaryRow(
              'Current Phase',
              widget.customer.currentPhaseDisplayName,
            ),
            _buildSummaryRow(
              'Material Status',
              widget.customer.materialAllocationStatusDisplayName,
            ),
            // Status-specific information
            if (widget.customer.materialAllocationStatus == 'pending')
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ready to create material allocation plan',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )
            else if (widget.customer.materialAllocationStatus == 'planned')
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.edit_note, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Plan saved as draft - ready to confirm allocation',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )
            else if (widget.customer.materialAllocationStatus == 'allocated')
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Materials allocated - ready for delivery',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.customer.materialAllocationDate != null)
              _buildSummaryRow(
                'Allocation Date',
                widget.customer.materialAllocationDate!.toString().split(' ')[0],
              ),
            if (widget.customer.isMaterialAllocationComplete)
              _buildSummaryRow(
                'Allocation Progress',
                '${widget.customer.materialAllocationCompletionPercentage.toStringAsFixed(1)}%',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildMaterialRequirements() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Material Requirements & Stock Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_stockItems.isEmpty)
              Card(
                color: Colors.yellow.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 48),
                      const SizedBox(height: 8),
                      const Text(
                        'No Stock Items Found',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Office: ${widget.office.name}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _createSampleStockItems,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Sample Stock Items'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_allocationPlan.isEmpty)
              const Center(
                child: Text(
                  'Set required quantities to see allocation plan',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            else
              ..._allocationPlan.entries.map((entry) {
                return _buildMaterialItem(entry.key, entry.value);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialItem(String itemId, Map<String, dynamic> itemData) {
    final itemName = itemData['item_name'] as String;
    final required = itemData['required'] as int;
    final available = itemData['available'] as int;
    final status = itemData['status'] as String;
    final shortage = itemData['shortage'] as int;
    final unit = itemData['unit'] as String;

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'available':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'partial':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      case 'unavailable':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available: $available $unit',
                      style: const TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                    if (shortage > 0)
                      Text(
                        'Shortage: $shortage $unit',
                        style: const TextStyle(fontSize: 14, color: Colors.red),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Manual quantity controls
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Required',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: required > 0
                            ? () =>
                                  _updateRequiredQuantity(itemId, required - 1)
                            : null,
                        icon: const Icon(Icons.remove),
                        iconSize: 20,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$required',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _updateRequiredQuantity(itemId, required + 1),
                        icon: const Icon(Icons.add),
                        iconSize: 20,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Allocation Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // Show saved plan indicator
                if (widget.customer.hasMaterialAllocationPlan && !_hasUnsavedChanges)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Saved',
                          style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                else if (_hasUnsavedChanges)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 14, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          'Modified',
                          style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                // Debug info for development
                if (_stockItems.isNotEmpty && _allocationPlan.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_stockItems.length} items, ${_allocationPlan.length} planned',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionPlan(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _hasUnsavedChanges || !widget.customer.hasMaterialAllocationPlan
                        ? _saveDraftAllocation
                        : null,
                    icon: const Icon(Icons.save),
                    label: Text(widget.customer.hasMaterialAllocationPlan ? 'Update Plan' : 'Save as Draft'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _canAllocateAll() && widget.customer.materialAllocationStatus != 'allocated'
                        ? _allocateMaterials
                        : null,
                    icon: const Icon(Icons.check_circle),
                    label: Text(widget.customer.materialAllocationStatus == 'allocated' 
                        ? 'Already Allocated' 
                        : 'Confirm Allocation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.customer.materialAllocationStatus == 'allocated' 
                          ? Colors.grey 
                          : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _hasPartialStock() && widget.customer.materialAllocationStatus != 'allocated'
                        ? _createPartialAllocation
                        : null,
                    icon: Icon(_hasPartialStock() 
                        ? Icons.inventory 
                        : Icons.warning),
                    label: Text(_hasPartialStock() 
                        ? 'Proceed with Available Stock' 
                        : 'No Stock Available'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasPartialStock() 
                          ? Colors.orange 
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.customer.materialAllocationStatus == 'allocated'
                        ? _markAsDelivered
                        : null,
                    icon: const Icon(Icons.local_shipping),
                    label: const Text('Mark Delivered'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.customer.materialAllocationStatus == 'allocated'
                          ? Colors.purple
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPlan() {
    List<String> actions = [];
    int availableCount = 0;
    int shortageCount = 0;

    _allocationPlan.forEach((itemId, itemData) {
      final itemName = itemData['item_name'] as String;
      final status = itemData['status'] as String;
      final shortage = itemData['shortage'] as int;
      final unit = itemData['unit'] as String;
      final required = itemData['required'] as int;

      if (required > 0) {
        if (status == 'partial' || status == 'unavailable') {
          actions.add('⚠️ $itemName: Need to procure $shortage $unit');
          shortageCount++;
        } else if (status == 'available') {
          actions.add('✅ $itemName: Ready for allocation');
          availableCount++;
        }
      }
    });

    if (actions.isEmpty) {
      actions.add('📋 Set required quantities to see action plan');
    }

    // Add summary guidance
    if (availableCount > 0 && shortageCount > 0) {
      actions.insert(0, '🔄 Mixed Stock Status: You can proceed with $availableCount available items');
      actions.insert(1, '📦 $shortageCount items need procurement - allocate them later when stock arrives');
    } else if (availableCount > 0 && shortageCount == 0) {
      actions.insert(0, '🎯 All items available - ready for complete allocation');
    } else if (shortageCount > 0 && availableCount == 0) {
      actions.insert(0, '🛒 All items need procurement - wait for stock or modify requirements');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (availableCount > 0 && shortageCount > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Recommendation: Proceed with Partial Allocation',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('• Work can start with available materials'),
                const Text('• Remaining items can be allocated when stock arrives'),
                const Text('• Customer project won\'t be delayed'),
              ],
            ),
          ),
        ...actions.map((action) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: Text(action, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  bool _canAllocateAll() {
    if (_allocationPlan.isEmpty) return false;

    return _allocationPlan.values.every(
      (item) => item['status'] == 'available',
    );
  }

  bool _hasPartialStock() {
    if (_allocationPlan.isEmpty) return false;

    return _allocationPlan.values.any(
      (item) => item['status'] == 'available' && (item['required'] as int) > 0,
    );
  }

  void _allocateMaterials() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Material Allocation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allocate all required materials for ${widget.customer.name}?',
            ),
            const SizedBox(height: 16),
            const Text(
              'This action will:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Reserve materials from stock'),
            const Text('• Generate allocation document'),
            const Text('• Move customer to Material Delivery phase'),
            const Text('• Send notification to field team'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processMaterialAllocation(isComplete: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Allocation'),
          ),
        ],
      ),
    );
  }

  void _createPartialAllocation() {
    // Calculate what can be allocated vs what's missing
    int availableItems = 0;
    List<String> availableItemNames = [];
    List<String> shortageItemNames = [];

    _allocationPlan.forEach((itemId, itemData) {
      final status = itemData['status'] as String;
      final itemName = itemData['item_name'] as String;
      final required = itemData['required'] as int;
      
      if (required > 0) {
        if (status == 'available') {
          availableItems++;
          availableItemNames.add(itemName);
        } else if (status == 'partial' || status == 'unavailable') {
          shortageItemNames.add(itemName);
        }
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Proceed with Partial Allocation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Allocation Summary for ${widget.customer.name}:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              if (availableItems > 0) ...[
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$availableItems items ready for allocation',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...availableItemNames.take(3).map((name) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Text('• $name', style: const TextStyle(fontSize: 13)),
                  )
                ).toList(),
                if (availableItemNames.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Text('• ... and ${availableItemNames.length - 3} more', 
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ),
                const SizedBox(height: 12),
              ],
              
              if (shortageItemNames.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.pending, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${shortageItemNames.length} items have shortages',
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...shortageItemNames.take(3).map((name) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Text('• $name', style: const TextStyle(fontSize: 13)),
                  )
                ).toList(),
                if (shortageItemNames.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Text('• ... and ${shortageItemNames.length - 3} more', 
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ),
                const SizedBox(height: 12),
              ],

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What happens next:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    SizedBox(height: 8),
                    Text('✓ Available items will be allocated immediately'),
                    Text('✓ Work can proceed with available materials'),
                    Text('✓ Shortage items remain as "pending"'),
                    Text('✓ You can allocate remaining items when stock arrives'),
                    Text('✓ Customer stays in material allocation phase'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: availableItems > 0 ? () {
              Navigator.pop(context);
              _processMaterialAllocation(isComplete: false);
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: availableItems > 0 ? Colors.orange : Colors.grey,
              foregroundColor: Colors.white,
            ),
            child: Text(availableItems > 0 
              ? 'Proceed with $availableItems Items' 
              : 'No Items Available'),
          ),
        ],
      ),
    );
  }

  void _processMaterialAllocation({required bool isComplete}) async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        _showMessage('User not authenticated');
        return;
      }

      // First save the plan if there are unsaved changes
      if (_hasUnsavedChanges) {
        await _saveDraftAllocation();
      }

      // Validate the allocation plan
      final validation = await SimplifiedMaterialAllocationService.validateAllocationPlan(
        customerId: widget.customer.id,
      );

      if (!validation['valid']) {
        final errors = validation['errors'] as List<String>;
        _showValidationErrors(errors);
        return;
      }

  // Show action buttons based on role and status
  Widget _buildActionButtons() {
    return FutureBuilder(
      future: _authService.getCurrentUser(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 40,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final currentUser = snapshot.data!;
        final userRole = currentUser.role.toLowerCase();
        final currentStatus = widget.customer.materialAllocationStatus;
        
        return Row(
          children: [
            // Save as Draft button - Available to Lead, Manager, Director
            if (SimplifiedMaterialAllocationService.canEditAllocation(userRole, currentStatus))
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _saveAsDraft(),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save as Draft'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            
            const SizedBox(width: 8),
            
            // Proceed button - Available to Manager, Director only  
            if (SimplifiedMaterialAllocationService.canProceedAllocation(userRole, currentStatus))
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _proceedWithAllocation(),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Proceed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            
            const SizedBox(width: 8),
            
            // Confirm button - Director only
            if (SimplifiedMaterialAllocationService.canConfirmAllocation(userRole, currentStatus))
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmAllocation(),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Confirm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Save as draft (planned status)
  Future<void> _saveAsDraft() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final allocationPlan = _buildAllocationPlan();
      
      await SimplifiedMaterialAllocationService.saveAsDraft(
        customerId: widget.customer.id,
        allocationPlan: allocationPlan,
        plannedById: widget.currentUser.id,
        notes: 'Material allocation plan saved as draft',
      );

      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Material allocation saved as draft'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to save draft: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Proceed with allocation (allocated status)
  Future<void> _proceedWithAllocation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final allocationPlan = _buildAllocationPlan();
      
      await SimplifiedMaterialAllocationService.proceedWithAllocation(
        customerId: widget.customer.id,
        allocatedById: widget.currentUser.id,
        updatedAllocationPlan: allocationPlan,
        notes: 'Material allocation proceeded by ${widget.currentUser.role}',
      );

      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Material allocation proceeded - awaiting director confirmation'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to proceed with allocation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Confirm allocation (confirmed status) - Triggers stock deduction
  Future<void> _confirmAllocation() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Material Allocation'),
        content: const Text(
          'This will confirm the allocation and deduct materials from stock. '
          'Stock can go negative if there are shortages. This action cannot be undone.\n\n'
          'Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await SimplifiedMaterialAllocationService.confirmAllocation(
        customerId: widget.customer.id,
        confirmedById: widget.currentUser.id,
      );

      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Material allocation confirmed! Stock updated and visible to all employees.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to confirm allocation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

      // Show results
      String message = isComplete && allAllocated
          ? 'Complete material allocation processed and confirmed successfully!'
          : 'Allocation plan updated. Review stock availability for complete allocation.';

      if (mounted) {
        _showMessage(message);
      }

      // Show allocation details
      if (allocationDetails.isNotEmpty && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(isComplete ? 'Allocation Confirmed' : 'Allocation Saved'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer: ${widget.customer.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Status: ${isComplete ? "Materials Allocated" : "Plan Saved"}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...allocationDetails
                    .map(
                      (detail) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(detail),
                      ),
                    )
                    .toList(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      // Refresh data
      await _loadStockData();
    } catch (e) {
      _showMessage('Error processing allocation: $e');
    }
  }

  void _showValidationErrors(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stock Validation Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The following items have insufficient stock:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...errors.map(
              (error) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $error'),
              ),
            ).toList(),
            const SizedBox(height: 12),
            const Text(
              'Please adjust quantities or procure additional stock before confirming.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Mark materials as delivered
  Future<void> _markAsDelivered() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        _showMessage('User not authenticated');
        return;
      }

      // Confirm delivery action
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Material Delivery'),
          content: Text(
            'Mark materials as delivered for ${widget.customer.name}?\n\n'
            'This will:\n'
            '• Update customer status to "Materials Delivered"\n'
            '• Advance customer to Installation phase\n'
            '• Complete the material allocation process'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Delivery'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await SimplifiedMaterialAllocationService.markMaterialsDelivered(
          customerId: widget.customer.id,
          deliveredById: currentUser.id,
        );

        _showMessage('Materials marked as delivered successfully!');
        
        // Refresh data to show updated status
        await _loadStockData();
      }
    } catch (e) {
      _showMessage('Error marking materials as delivered: $e');
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: _stockItems.isEmpty
              ? SnackBarAction(
                  label: 'Add Stock',
                  onPressed: () => _showNoStockDialog(),
                )
              : null,
        ),
      );
    }
  }

  void _showNoStockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Stock Items Found'),
        content: const Text(
          'There are no stock items in this office. Would you like to create some sample solar installation materials to get started?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createSampleStockItems();
            },
            child: const Text('Create Samples'),
          ),
        ],
      ),
    );
  }

  Future<void> _createSampleStockItems() async {
    try {
      final sampleItems = [
        {'name': 'Solar Panel 540W', 'stock': 50},
        {'name': 'Solar Inverter 5kW', 'stock': 10},
        {'name': 'MC4 Connector', 'stock': 200},
        {'name': 'DC Cable 4mm', 'stock': 500},
        {'name': 'AC Cable 6mm', 'stock': 300},
        {'name': 'Mounting Structure', 'stock': 100},
        {'name': 'Battery 100Ah', 'stock': 20},
        {'name': 'Charge Controller', 'stock': 15},
      ];

      for (final item in sampleItems) {
        final stockItem = StockItemModel(
          name: item['name'] as String,
          currentStock: item['stock'] as int,
          officeId: widget.office.id,
        );

        await _stockService.createStockItem(stockItem);
      }

      _showMessage('Sample stock items created successfully!');
      await _loadStockData();
    } catch (e) {
      _showMessage('Error creating sample items: $e');
    }
  }

  // Save current allocation as draft
  Future<void> _saveDraftAllocation() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        _showMessage('User not authenticated');
        return;
      }

      // Check if we have any requirements to save
      final hasRequirements = _manualRequirements.values.any((qty) => qty > 0);
      if (!hasRequirements) {
        _showMessage('Please set some required quantities before saving');
        return;
      }

      // Create stock items map for plan creation
      final stockItemsMap = <String, StockItemModel>{};
      for (final item in _stockItems) {
        if (item.id != null) {
          stockItemsMap[item.id!] = item;
        }
      }

      // Create allocation plan
      final allocationPlan = SimplifiedMaterialAllocationService.createAllocationPlan(
        requirements: _manualRequirements,
        stockItems: stockItemsMap,
      );

      // Save to customer record
      await SimplifiedMaterialAllocationService.saveAsDraft(
        customerId: widget.customer.id,
        allocationPlan: allocationPlan,
        plannedById: currentUser.id,
        notes: 'Material allocation plan for ${widget.customer.name}',
      );

      setState(() {
        _hasUnsavedChanges = false;
      });

      _showMessage('Allocation plan saved as draft successfully!');
    } catch (e) {
      _showMessage('Error saving allocation: $e');
    }
  }
}
