import 'package:flutter/material.dart';
import '../../models/stock_item_model.dart';
import '../../models/stock_log_model.dart';
import '../../services/stock_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class StockInventoryScreen extends StatefulWidget {
  const StockInventoryScreen({super.key});

  @override
  State<StockInventoryScreen> createState() => _StockInventoryScreenState();
}

class _StockInventoryScreenState extends State<StockInventoryScreen>
    with SingleTickerProviderStateMixin {
  final StockService _stockService = StockService();
  final AuthService _authService = AuthService();

  List<StockItemModel> _stockItems = [];
  List<StockLogModel> _stockLogs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  UserModel? _currentUser;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUser = await _authService.getCurrentUser();

      if (_currentUser != null && _currentUser!.officeId != null) {
        final officeId = _currentUser!.officeId!;

        _stockItems = await _stockService.getStockItemsByOffice(officeId);
        _stockLogs = await _stockService.getStockLog(officeId: officeId);
      }
    } catch (e) {
      _showMessage('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<StockItemModel> get _filteredItems {
    if (_searchQuery.isEmpty) {
      return _stockItems;
    }
    return _stockItems
        .where(
          (item) =>
              item.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showAddItemDialog() async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '0');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Stock Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Initial Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, {
                'name': nameController.text.trim(),
                'quantity': int.tryParse(quantityController.text) ?? 0,
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && _currentUser?.officeId != null) {
      try {
        final officeId = _currentUser!.officeId!;
        final newItem = StockItemModel(
          name: result['name'],
          currentStock: result['quantity'],
          officeId: officeId,
        );

        await _stockService.createStockItem(newItem);
        await _loadData();
        _showMessage('Item added successfully');
      } catch (e) {
        _showMessage('Error adding item: $e');
      }
    }
  }

  Future<void> _showUpdateStockDialog(StockItemModel item) async {
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();
    String selectedAction = 'add';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Update Stock: ${item.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current Stock: ${item.currentStock}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedAction,
                decoration: const InputDecoration(
                  labelText: 'Action',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'add', child: Text('Add Stock')),
                  DropdownMenuItem(
                    value: 'decrease',
                    child: Text('Decrease Stock'),
                  ),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedAction = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final quantity = int.tryParse(quantityController.text);
                if (quantity == null || quantity <= 0) {
                  return;
                }
                Navigator.pop(context, {
                  'action': selectedAction,
                  'quantity': quantity,
                  'reason': reasonController.text.trim().isEmpty
                      ? null
                      : reasonController.text.trim(),
                });
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    if (result != null && item.id != null) {
      try {
        await _stockService.updateStockQuantity(
          stockItemId: item.id!,
          action: result['action'],
          quantity: result['quantity'],
          reason: result['reason'],
        );
        await _loadData();
        _showMessage('Stock updated successfully');
      } catch (e) {
        _showMessage('Error updating stock: $e');
      }
    }
  }

  Widget _buildItemsTab() {
    return Column(
      children: [
        // Search and Add button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search items...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              FloatingActionButton(
                mini: true,
                onPressed: _showAddItemDialog,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        // Items list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredItems.isEmpty
              ? const Center(
                  child: Text(
                    'No stock items found.\nTap + to add your first item.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Stock: ${item.currentStock}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showUpdateStockDialog(item),
                            ),
                            if (item.id != null)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Item'),
                                      content: Text(
                                        'Are you sure you want to delete "${item.name}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      await _stockService.deleteStockItem(
                                        item.id!,
                                      );
                                      await _loadData();
                                      _showMessage('Item deleted successfully');
                                    } catch (e) {
                                      _showMessage('Error deleting item: $e');
                                    }
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _stockLogs.isEmpty
        ? const Center(
            child: Text(
              'No stock history found.',
              style: TextStyle(fontSize: 16),
            ),
          )
        : ListView.builder(
            itemCount: _stockLogs.length,
            itemBuilder: (context, index) {
              final log = _stockLogs[index];
              final item = _stockItems.firstWhere(
                (item) => item.id == log.stockItemId,
                orElse: () => StockItemModel(
                  name: 'Unknown Item',
                  currentStock: 0,
                  officeId: '0',
                ),
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: log.action == 'add'
                        ? Colors.green
                        : Colors.orange,
                    child: Icon(
                      log.action == 'add' ? Icons.add : Icons.remove,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(item.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${log.action.toUpperCase()}: ${log.quantity} (${log.previousStock} → ${log.newStock})',
                      ),
                      if (log.reason?.isNotEmpty == true)
                        Text('Reason: ${log.reason}'),
                      if (log.createdAt != null)
                        Text(
                          'Date: ${log.createdAt!.day}/${log.createdAt!.month}/${log.createdAt!.year} ${log.createdAt!.hour}:${log.createdAt!.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory), text: 'Items'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildItemsTab(), _buildHistoryTab()],
      ),
    );
  }
}
