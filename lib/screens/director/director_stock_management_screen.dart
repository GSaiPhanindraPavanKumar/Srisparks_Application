import 'package:flutter/material.dart';
import '../../models/stock_item_model.dart';
import '../../models/stock_log_model.dart';
import '../../models/user_model.dart';
import '../../models/office_model.dart';
import '../../services/stock_service.dart';
import '../../services/auth_service.dart';
import '../../services/office_service.dart';

class DirectorStockManagementScreen extends StatefulWidget {
  const DirectorStockManagementScreen({super.key});

  @override
  State<DirectorStockManagementScreen> createState() => _DirectorStockManagementScreenState();
}

class _DirectorStockManagementScreenState extends State<DirectorStockManagementScreen>
    with SingleTickerProviderStateMixin {
  final StockService _stockService = StockService();
  final AuthService _authService = AuthService();
  final OfficeService _officeService = OfficeService();
  
  List<StockItemModel> stockItems = [];
  List<StockLogModel> stockLogs = [];
  List<OfficeModel> availableOffices = [];
  bool isLoading = true;
  UserModel? currentUser;
  String? selectedOfficeId;
  OfficeModel? selectedOffice;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    
    try {
      final user = await _authService.getCurrentUser();
      print('Director user: ${user?.email}, Role: ${user?.role}');
      
      if (user != null) {
        currentUser = user;
        
        // Load all available offices for director
        availableOffices = await _officeService.getAllOffices();
        print('Loaded ${availableOffices.length} offices for director');
        
        setState(() {
          stockItems = [];
          stockLogs = [];
        });
      }
    } catch (e) {
      print('Error loading initial data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadStockForOffice(String officeId) async {
    setState(() => isLoading = true);
    
    try {
      selectedOfficeId = officeId;
      selectedOffice = availableOffices.firstWhere((office) => office.id == officeId);
      
      print('Loading stock for selected office: $officeId (${selectedOffice?.name})');
      
      final items = await _stockService.getStockItemsByOffice(officeId);
      final logs = await _stockService.getStockLog(officeId: officeId);
      
      print('Loaded ${items.length} items and ${logs.length} logs for office $officeId');
      
      setState(() {
        stockItems = items;
        stockLogs = logs;
      });
    } catch (e) {
      print('Error loading stock for office: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading stock for office: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _showAddItemDialog() async {
    if (selectedOfficeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an office first')),
      );
      return;
    }

    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '0');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Item to ${selectedOffice?.name ?? 'Selected Office'}'),
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
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Initial Quantity',
                border: OutlineInputBorder(),
              ),
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

    if (result != null) {
      try {
        final newItem = StockItemModel(
          name: result['name'],
          currentStock: result['quantity'],
          officeId: selectedOfficeId!,
        );
        
        await _stockService.createStockItem(newItem);
        await _loadStockForOffice(selectedOfficeId!);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating item: $e')),
        );
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
                  DropdownMenuItem(value: 'decrease', child: Text('Decrease Stock')),
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
        await _loadStockForOffice(selectedOfficeId!);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating stock: $e')),
        );
      }
    }
  }

  Widget _buildOfficeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.business, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedOfficeId,
              decoration: const InputDecoration(
                labelText: 'Select Office',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Choose an office to manage'),
              items: availableOffices.map((office) {
                return DropdownMenuItem<String>(
                  value: office.id,
                  child: Text(
                    '${office.name}${office.city != null && office.city!.isNotEmpty ? ' - ${office.city}' : ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (String? officeId) {
                if (officeId != null) {
                  _loadStockForOffice(officeId);
                }
              },
            ),
          ),
          if (selectedOfficeId != null) ...[
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadStockForOffice(selectedOfficeId!),
              tooltip: 'Refresh',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStockItemsTab() {
    if (selectedOfficeId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Please select an office',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Choose an office from the dropdown above to manage its stock',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (stockItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No stock items in ${selectedOffice?.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + to add your first item',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stockItems.length,
      itemBuilder: (context, index) {
        final item = stockItems[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: item.currentStock > 0 
                  ? Colors.green.shade100 
                  : Colors.red.shade100,
              child: Icon(
                Icons.inventory_2,
                color: item.currentStock > 0 
                    ? Colors.green.shade700 
                    : Colors.red.shade700,
              ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Stock: ${item.currentStock} units'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showUpdateStockDialog(item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
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
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && item.id != null) {
                      try {
                        await _stockService.deleteStockItem(item.id!);
                        await _loadStockForOffice(selectedOfficeId!);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Item deleted successfully')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error deleting item: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    if (selectedOfficeId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Please select an office',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Choose an office from the dropdown above to view its stock history',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (stockLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No stock history in ${selectedOffice?.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stockLogs.length,
      itemBuilder: (context, index) {
        final log = stockLogs[index];
        final item = stockItems.firstWhere(
          (item) => item.id == log.stockItemId,
          orElse: () => StockItemModel(
            name: 'Unknown Item',
            currentStock: 0,
            officeId: selectedOfficeId!,
          ),
        );

        // Determine the icon and color based on action
        IconData iconData;
        Color backgroundColor;
        Color iconColor;
        
        switch (log.action) {
          case 'add':
            iconData = Icons.add;
            backgroundColor = Colors.green.shade100;
            iconColor = Colors.green.shade700;
            break;
          case 'decrease':
            iconData = Icons.remove;
            backgroundColor = Colors.orange.shade100;
            iconColor = Colors.orange.shade700;
            break;
          case 'delete':
            iconData = Icons.delete;
            backgroundColor = Colors.red.shade100;
            iconColor = Colors.red.shade700;
            break;
          default:
            iconData = Icons.help;
            backgroundColor = Colors.grey.shade100;
            iconColor = Colors.grey.shade700;
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: backgroundColor,
              child: Icon(iconData, color: iconColor),
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
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
        title: selectedOffice != null 
          ? Text(
              'Stock: ${selectedOffice!.name}${selectedOffice!.city != null && selectedOffice!.city!.isNotEmpty ? ' - ${selectedOffice!.city}' : ''}',
              style: const TextStyle(fontSize: 16),
            )
          : const Text('Director - Stock Management'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        bottom: selectedOfficeId != null ? TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory), text: 'Items'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ) : null,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildOfficeSelector(),
                if (selectedOfficeId != null)
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildStockItemsTab(),
                        _buildHistoryTab(),
                      ],
                    ),
                  )
                else
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business,
                            size: 100,
                            color: Colors.blue,
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Welcome Director!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Select an office from the dropdown above to manage its stock',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: selectedOfficeId != null ? FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}
