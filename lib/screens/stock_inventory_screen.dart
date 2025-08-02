import 'package:flutter/material.dart';
import '../models/stock_item_model.dart';
import '../models/stock_log_model.dart';
import '../models/user_model.dart';
import '../models/office_model.dart';
import '../services/stock_service.dart';
import '../services/auth_service.dart';
import '../services/office_service.dart';

class StockInventoryScreen extends StatefulWidget {
  const StockInventoryScreen({super.key});

  @override
  State<StockInventoryScreen> createState() => _StockInventoryScreenState();
}

class _StockInventoryScreenState extends State<StockInventoryScreen> {
  final StockService _stockService = StockService();
  final AuthService _authService = AuthService();
  final OfficeService _officeService = OfficeService();
  
  List<StockItemModel> stockItems = [];
  List<StockLogModel> stockLogs = [];
  bool isLoading = true;
  UserModel? currentUser;
  String? selectedOfficeId;
  List<OfficeModel> availableOffices = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      final user = await _authService.getCurrentUser();
      print('Current user: ${user?.email}, Role: ${user?.role}, Office ID: ${user?.officeId}');
      
      if (user != null) {
        currentUser = user;
        
        // Load available offices for directors
        if (user.role == UserRole.director) {
          availableOffices = await _officeService.getAllOffices();
          print('Loaded ${availableOffices.length} offices for director');
        }
        
        // For users with specific office assignment
        if (user.officeId != null && user.officeId!.isNotEmpty) {
          selectedOfficeId = user.officeId;
          print('Loading stock for office: $selectedOfficeId');
          
          final items = await _stockService.getStockItemsByOffice(user.officeId!);
          final logs = await _stockService.getStockLog(officeId: user.officeId!);
          
          print('Loaded ${items.length} items and ${logs.length} logs');
          
          setState(() {
            stockItems = items;
            stockLogs = logs;
          });
        } else if (user.role == UserRole.director) {
          // Directors without office assignment - show office selection
          print('Director without office assignment - showing office selection');
          setState(() {
            stockItems = [];
            stockLogs = [];
          });
        } else {
          // Other users without office assignment - show error
          print('User has no office assigned');
          setState(() {
            stockItems = [];
            stockLogs = [];
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please contact administrator to assign an office for stock management'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error loading data: $e');
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
      print('Loading stock for selected office: $officeId');
      
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
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '0');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item'),
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
            onPressed: () async {
              if (nameController.text.isNotEmpty && selectedOfficeId != null) {
                final newItem = StockItemModel(
                  name: nameController.text,
                  currentStock: int.tryParse(quantityController.text) ?? 0,
                  officeId: selectedOfficeId!,
                );
                
                try {
                  await _stockService.createStockItem(newItem);
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating item: $e')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please ensure you have an office assigned')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateStockDialog(StockItemModel item) async {
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();
    String selectedAction = 'add';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Update Stock - ${item.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Stock: ${item.currentStock}'),
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
                  if (value != null) {
                    setDialogState(() => selectedAction = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
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
              onPressed: () async {
                final quantity = int.tryParse(quantityController.text);
                if (quantity != null && quantity > 0) {
                  try {
                    final success = await _stockService.updateStockQuantity(
                      stockItemId: item.id!,
                      action: selectedAction,
                      quantity: quantity,
                      reason: reasonController.text.isNotEmpty 
                          ? reasonController.text 
                          : null,
                    );
                    
                    Navigator.pop(context);
                    
                    if (success) {
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stock updated successfully')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to update stock')),
                      );
                    }
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          if (currentUser?.role == UserRole.director && selectedOfficeId != null)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Switch Office',
              onPressed: () {
                setState(() {
                  selectedOfficeId = null;
                  stockItems = [];
                  stockLogs = [];
                });
              },
            ),
          if (currentUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  currentUser!.role == UserRole.director 
                    ? (selectedOfficeId != null 
                        ? () {
                            final office = availableOffices.firstWhere(
                              (o) => o.id == selectedOfficeId, 
                              orElse: () => OfficeModel(id: '', name: 'Unknown', isActive: true, createdAt: DateTime.now())
                            );
                            return 'Director: ${office.name}${office.city != null && office.city!.isNotEmpty ? ' - ${office.city}' : ''}';
                          }()
                        : 'Director View')
                    : 'Office: ${selectedOfficeId ?? "Not Assigned"}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: selectedOfficeId == null 
          ? _buildNoOfficeView()
          : isLoading
              ? const Center(child: CircularProgressIndicator())
              : DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(icon: Icon(Icons.inventory_2), text: 'Items'),
                          Tab(icon: Icon(Icons.history), text: 'History'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildStockItemsTab(),
                            _buildStockHistoryTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: selectedOfficeId != null ? FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildNoOfficeView() {
    // For directors, show office selection
    if (currentUser?.role == UserRole.director && availableOffices.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.business,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Office',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose an office to manage its stock.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableOffices.length,
                itemBuilder: (context, index) {
                  final office = availableOffices[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.business_center),
                      title: Text(office.name),
                      subtitle: Text(office.address ?? office.city ?? 'No address'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _loadStockForOffice(office.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
    
    // For other users without office assignment
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.business_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Office Assigned',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'You need to be assigned to an office to manage stock.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please contact your administrator to assign you to an office'),
                ),
              );
            },
            child: const Text('Contact Administrator'),
          ),
        ],
      ),
    );
  }

  Widget _buildStockItemsTab() {
    if (stockItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No stock items found'),
            Text('Tap + to add your first item'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stockItems.length,
        itemBuilder: (context, index) {
          final item = stockItems[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
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
                          content: Text('Are you sure you want to delete ${item.name}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && item.id != null) {
                        try {
                          await _stockService.deleteStockItem(item.id!);
                          _loadData();
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
      ),
    );
  }

  Widget _buildStockHistoryTab() {
    if (stockLogs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No stock history found'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stockLogs.length,
        itemBuilder: (context, index) {
          final log = stockLogs[index];
          final isIncrease = log.action == 'add';
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isIncrease 
                    ? Colors.green.shade100 
                    : Colors.orange.shade100,
                child: Icon(
                  isIncrease ? Icons.add : Icons.remove,
                  color: isIncrease 
                      ? Colors.green.shade700 
                      : Colors.orange.shade700,
                ),
              ),
              title: Text(
                '${isIncrease ? '+' : '-'}${log.quantity} units',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isIncrease ? Colors.green : Colors.orange,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stock: ${log.previousStock} → ${log.newStock}'),
                  if (log.reason != null) Text('Reason: ${log.reason}'),
                  Text(
                    log.createdAt != null 
                        ? log.createdAt!.toLocal().toString().split('.')[0]
                        : 'Unknown time',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
