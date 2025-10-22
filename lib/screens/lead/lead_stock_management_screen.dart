import 'package:flutter/material.dart';
import '../../models/stock_item_model.dart';
import '../../models/stock_log_model.dart';
import '../../models/user_model.dart';
import '../../models/office_model.dart';
import '../../services/stock_service.dart';
import '../../services/auth_service.dart';
import '../../services/office_service.dart';

class LeadStockManagementScreen extends StatefulWidget {
  const LeadStockManagementScreen({super.key});

  @override
  State<LeadStockManagementScreen> createState() =>
      _LeadStockManagementScreenState();
}

class _LeadStockManagementScreenState extends State<LeadStockManagementScreen>
    with SingleTickerProviderStateMixin {
  final StockService _stockService = StockService();
  final AuthService _authService = AuthService();
  final OfficeService _officeService = OfficeService();

  List<StockItemModel> stockItems = [];
  List<StockLogModel> stockLogs = [];
  bool isLoading = true;
  UserModel? currentUser;
  OfficeModel? currentOffice;

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
      print(
        'Lead user: ${user?.email}, Role: ${user?.role}, Office: ${user?.officeId}',
      );

      if (user != null && user.officeId != null) {
        currentUser = user;

        // Load the lead's office
        currentOffice = await _officeService.getOfficeById(user.officeId!);
        print('Loaded office: ${currentOffice?.name} (${currentOffice?.id})');

        // Load stock for the lead's office
        await _loadStockForOffice();
      } else {
        print('Lead has no office assigned');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No office assigned to your account. Please contact director.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading initial data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadStockForOffice() async {
    if (currentOffice == null) return;

    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      print(
        'Loading stock for office: ${currentOffice!.id} (${currentOffice!.name})',
      );

      final items = await _stockService.getStockItemsByOffice(
        currentOffice!.id,
      );
      final logs = await _stockService.getStockLog(officeId: currentOffice!.id);

      print(
        'Loaded ${items.length} items and ${logs.length} logs for office ${currentOffice!.id}',
      );

      if (mounted) {
        setState(() {
          stockItems = items;
          stockLogs = logs;
        });
      }
    } catch (e) {
      print('Error loading stock for office: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stock for office: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _showAddItemDialog() async {
    if (currentOffice == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No office assigned')));
      return;
    }

    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '0');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Item to ${currentOffice?.name ?? 'Your Office'}'),
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

    if (result != null && currentOffice?.id != null) {
      try {
        final newItem = StockItemModel(
          name: result['name'],
          currentStock: result['quantity'],
          officeId: currentOffice!.id,
        );

        await _stockService.createStockItem(newItem);
        await _loadStockForOffice();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating item: $e')));
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
        await _loadStockForOffice();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating stock: $e')));
      }
    }
  }

  Widget _buildStockItemsTab() {
    if (currentOffice == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No office assigned',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Please contact director to assign you to an office',
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
            const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No stock items in ${currentOffice?.name}',
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
                        await _loadStockForOffice();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Item deleted successfully'),
                          ),
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
    if (currentOffice == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No office assigned',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Please contact director to assign you to an office',
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
              'No stock history in ${currentOffice?.name}',
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
            officeId: currentOffice!.id,
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
        title: currentOffice != null
            ? Text(
                'Stock: ${currentOffice!.name}${currentOffice!.city != null && currentOffice!.city!.isNotEmpty ? ' - ${currentOffice!.city}' : ''}',
                style: const TextStyle(fontSize: 16),
              )
            : const Text('Lead - Stock Management'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          if (currentOffice != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadStockForOffice,
              tooltip: 'Refresh',
            ),
        ],
        bottom: currentOffice != null
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.inventory), text: 'Items'),
                  Tab(icon: Icon(Icons.history), text: 'History'),
                ],
              )
            : null,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : currentOffice != null
          ? TabBarView(
              controller: _tabController,
              children: [_buildStockItemsTab(), _buildHistoryTab()],
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 100, color: Colors.teal),
                  SizedBox(height: 24),
                  Text(
                    'No Office Assigned',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please contact your director to assign you to an office',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
      floatingActionButton: currentOffice != null
          ? FloatingActionButton(
              onPressed: _showAddItemDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
