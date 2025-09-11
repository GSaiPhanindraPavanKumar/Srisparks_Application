import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../models/office_model.dart';
import '../../models/stock_item_model.dart';
import '../../models/user_model.dart';
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
  bool _isLoading = true;

  // Manual requirements - editable by user
  Map<String, int> _manualRequirements = {};

  // Track if allocation has been saved
  bool _hasUnsavedChanges = false;

  // Current user
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get current user
      _currentUser = await _authService.getCurrentUser();

      // Load actual stock data from the office
      print('Loading stock data for office: ${widget.office.id}');

      final stockItems = await _stockService.getStockItemsByOffice(
        widget.office.id,
      );

      if (stockItems.isEmpty) {
        print('No stock items found for office: ${widget.office.id}');
      } else {
        print('Found ${stockItems.length} stock items');
      }

      // Load existing allocation plan if any
      final existingPlan =
          widget.customer.materialAllocationPlanData ?? <String, dynamic>{};

      setState(() {
        _stockItems = stockItems;
        _manualRequirements = existingPlan.map(
          (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _saveAsDraft() async {
    if (_currentUser == null) return;

    try {
      setState(() => _isLoading = true);

      await SimplifiedMaterialAllocationService.saveAsDraft(
        customerId: widget.customer.id,
        allocationPlan: _buildAllocationPlan(),
        plannedById: _currentUser!.id,
        notes: 'Material allocation saved as draft',
      );

      setState(() => _hasUnsavedChanges = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material allocation saved as draft')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving draft: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _proceedWithAllocation() async {
    if (_currentUser == null) return;

    try {
      setState(() => _isLoading = true);

      await SimplifiedMaterialAllocationService.proceedWithAllocation(
        customerId: widget.customer.id,
        updatedAllocationPlan: _buildAllocationPlan(),
        allocatedById: _currentUser!.id,
        notes:
            'Material allocation proceeded by ${_currentUser!.role.displayName}',
      );

      setState(() => _hasUnsavedChanges = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material allocation proceeded')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error proceeding with allocation: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmAllocation() async {
    if (_currentUser == null) return;

    try {
      setState(() => _isLoading = true);

      await SimplifiedMaterialAllocationService.confirmAllocation(
        customerId: widget.customer.id,
        confirmedById: _currentUser!.id,
      );

      setState(() => _hasUnsavedChanges = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Material allocation confirmed! Stock has been deducted.',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error confirming allocation: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _buildAllocationPlan() {
    final plan = <String, dynamic>{};
    for (final entry in _manualRequirements.entries) {
      if (entry.value > 0) {
        plan[entry.key] = entry.value;
      }
    }
    return plan;
  }

  Widget _buildActionButtons() {
    if (_currentUser == null) return const SizedBox();

    final userRole = _currentUser!.role.name;
    final isUserLead = _currentUser!.isLead;
    final status = widget.customer.materialAllocationStatus;

    // Debug information
    print('Material Allocation Debug:');
    print('User Role: $userRole');
    print('Is Lead: $isUserLead');
    print('Material Status: $status');
    print('Role Display Name: ${_currentUser!.roleDisplayName}');

    List<Widget> buttons = [];

    // Save as Draft - Available for Lead (including isLead=true employees), Manager, Director when status is pending or planned
    final hasLeadPermissions =
        ['lead', 'manager', 'director'].contains(userRole) ||
        (userRole == 'employee' && isUserLead);
    final canSaveAsDraft =
        hasLeadPermissions && ['pending', 'planned'].contains(status);

    print('Has Lead Permissions: $hasLeadPermissions');
    print('Can Save as Draft: $canSaveAsDraft');

    if (canSaveAsDraft) {
      buttons.add(
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Save as Draft'),
          onPressed: () => _saveAsDraft(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    // Proceed - Available for Manager, Director when status is planned
    if (['manager', 'director'].contains(userRole) && status == 'planned') {
      buttons.add(
        ElevatedButton.icon(
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Proceed'),
          onPressed: () => _proceedWithAllocation(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    // Confirm - Available only for Director when status is allocated
    if (userRole == 'director' && status == 'allocated') {
      buttons.add(
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle),
          label: const Text('Confirm'),
          onPressed: () => _confirmAllocation(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    if (buttons.isEmpty) {
      return const Text(
        'No actions available for your role and current status',
      );
    }

    return Wrap(spacing: 10, children: buttons);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Material Allocation - ${widget.customer.name}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer: ${widget.customer.name}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Status: ${widget.customer.materialAllocationStatus}',
                          ),
                          Text('Office: ${widget.office.name}'),
                          if (widget.customer.materialPlannedDate != null)
                            Text(
                              'Material Planned: ${widget.customer.materialPlannedDate!.toLocal().toString().split(' ')[0]}',
                            ),
                          if (widget.customer.materialAllocationDate != null)
                            Text(
                              'Material Allocated: ${widget.customer.materialAllocationDate!.toLocal().toString().split(' ')[0]}',
                            ),
                          if (_currentUser != null)
                            Text('Your Role: ${_currentUser!.roleDisplayName}'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stock Items
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stock Items',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          if (_stockItems.isEmpty)
                            const Text('No stock items available')
                          else
                            ..._stockItems.map(
                              (item) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(item.name),
                                  subtitle: Text(
                                    'Available: ${item.currentStock}',
                                  ),
                                  trailing: SizedBox(
                                    width: 100,
                                    child: TextFormField(
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Allocate',
                                        border: OutlineInputBorder(),
                                      ),
                                      initialValue:
                                          (_manualRequirements[item.id ?? ''] ??
                                                  0)
                                              .toString(),
                                      onChanged: (value) {
                                        final quantity =
                                            int.tryParse(value) ?? 0;
                                        final itemId = item.id ?? '';
                                        if (itemId.isNotEmpty) {
                                          setState(() {
                                            _manualRequirements[itemId] =
                                                quantity;
                                            _hasUnsavedChanges = true;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  _buildActionButtons(),

                  if (_hasUnsavedChanges)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'You have unsaved changes',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
