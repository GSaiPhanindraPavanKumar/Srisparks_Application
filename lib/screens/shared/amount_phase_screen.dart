import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../services/customer_service.dart';
import '../../services/auth_service.dart';

class AmountPhaseScreen extends StatefulWidget {
  const AmountPhaseScreen({super.key});

  @override
  State<AmountPhaseScreen> createState() => _AmountPhaseScreenState();
}

class _AmountPhaseScreenState extends State<AmountPhaseScreen>
    with SingleTickerProviderStateMixin {
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService();

  late TabController _tabController;

  UserModel? _currentUser;
  List<CustomerModel> _allAmountPhaseCustomers = [];
  List<CustomerModel> _pendingPaymentCustomers = [];
  List<CustomerModel> _partialPaymentCustomers = [];
  List<CustomerModel> _completedPaymentCustomers = [];

  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _currentUser = await _authService.getCurrentUser();

      if (_currentUser != null) {
        // Load amount phase customers based on user role
        if (_currentUser!.role == UserRole.director) {
          // Directors can see all amount phase customers
          _allAmountPhaseCustomers = await _customerService
              .getAllAmountPhaseCustomers();
        } else if (_currentUser!.officeId != null) {
          // Managers and employees see amount phase customers from their office
          _allAmountPhaseCustomers = await _customerService
              .getAmountPhaseCustomers(_currentUser!.officeId!);
        } else {
          _allAmountPhaseCustomers = [];
          _showMessage(
            'Error: User is not assigned to any office. Please contact administrator.',
          );
          return;
        }

        _filterCustomers();
      }
    } catch (e) {
      _showMessage('Error loading amount phase customers: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterCustomers() {
    final query = _searchQuery.toLowerCase();

    List<CustomerModel> filteredCustomers;

    if (query.isEmpty) {
      filteredCustomers = _allAmountPhaseCustomers;
    } else {
      filteredCustomers = _allAmountPhaseCustomers.where((customer) {
        return customer.name.toLowerCase().contains(query) ||
            customer.email?.toLowerCase().contains(query) == true ||
            customer.phoneNumber?.contains(query) == true ||
            customer.electricMeterServiceNumber?.toLowerCase().contains(
                  query,
                ) ==
                true;
      }).toList();
    }

    // Sort by application approval date (latest first)
    filteredCustomers.sort(
      (a, b) =>
          b.applicationApprovalDate?.compareTo(
            a.applicationApprovalDate ?? DateTime.now(),
          ) ??
          0,
    );

    // Filter by payment status
    _pendingPaymentCustomers = filteredCustomers
        .where((c) => c.amountPaymentStatus == 'pending')
        .toList();
    _partialPaymentCustomers = filteredCustomers
        .where((c) => c.amountPaymentStatus == 'partial')
        .toList();
    _completedPaymentCustomers = filteredCustomers
        .where((c) => c.amountPaymentStatus == 'completed')
        .toList();

    setState(() {});
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by name, phone, email, or service number...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _filterCustomers();
        },
      ),
    );
  }

  Widget _buildCustomersList(List<CustomerModel> customers) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No customers found in amount phase',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return _buildCustomerCard(customer);
      },
    );
  }

  Widget _buildCustomerCard(CustomerModel customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showAmountDetails(customer),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (customer.email != null)
                          Text(
                            customer.email!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        if (customer.phoneNumber != null)
                          Text(
                            customer.phoneNumber!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildPaymentStatusChip(customer),
                ],
              ),
              const SizedBox(height: 12),

              // Project details
              Row(
                children: [
                  Icon(Icons.solar_power, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(customer.projectSummary),
                ],
              ),
              const SizedBox(height: 8),

              // Amount details
              if (customer.amountTotal != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.currency_rupee,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Total: ₹${NumberFormat('#,##,###').format(customer.amountTotal)}',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (customer.amountPaid != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        'Paid: ₹${NumberFormat('#,##,###').format(customer.amountPaid)}',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Approval date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Approved: ${customer.applicationApprovalDate != null ? DateFormat('MMM dd, yyyy').format(customer.applicationApprovalDate!) : 'N/A'}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const Spacer(),

                  // Action indicator for directors/managers
                  if ((_currentUser?.role == UserRole.director ||
                          _currentUser?.role == UserRole.manager) &&
                      !customer.isAmountPhaseCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Action Required',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentStatusChip(CustomerModel customer) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String status = customer.amountPaymentStatusDisplayName;

    switch (customer.amountPaymentStatus) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        icon = Icons.pending_actions;
        break;
      case 'partial':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        icon = Icons.payment;
        break;
      case 'completed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showAmountDetails(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${customer.name} - Amount Phase'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Customer', customer.name),
              _buildDetailRow('Project', customer.projectSummary),
              _buildDetailRow(
                'Estimated kW',
                '${customer.estimatedKw ?? 'N/A'}',
              ),
              _buildDetailRow(
                'Final kW',
                '${customer.amountKw ?? customer.kw ?? 'Not set'}',
              ),
              _buildDetailRow(
                'Total Amount',
                customer.amountTotal != null
                    ? '₹${NumberFormat('#,##,###').format(customer.amountTotal)}'
                    : 'Not set',
              ),
              _buildDetailRow(
                'Paid Amount',
                customer.amountPaid != null
                    ? '₹${NumberFormat('#,##,###').format(customer.amountPaid)}'
                    : 'No payment recorded',
              ),
              _buildDetailRow(
                'Payment Status',
                customer.amountPaymentStatusDisplayName,
              ),
              if (customer.amountPaidDate != null)
                _buildDetailRow(
                  'Payment Date',
                  DateFormat('MMM dd, yyyy').format(customer.amountPaidDate!),
                ),
              if (customer.amountUtrNumber != null)
                _buildDetailRow('UTR Number', customer.amountUtrNumber!),
              if (customer.amountNotes != null &&
                  customer.amountNotes!.isNotEmpty)
                _buildDetailRow('Notes', customer.amountNotes!),
              if (customer.isAmountPhaseCompleted &&
                  customer.amountClearedDate != null)
                _buildDetailRow(
                  'Cleared Date',
                  DateFormat(
                    'MMM dd, yyyy',
                  ).format(customer.amountClearedDate!),
                ),
            ],
          ),
        ),
        actions: [
          // Only directors and managers can manage amount phase
          if ((_currentUser?.role == UserRole.director ||
                  _currentUser?.role == UserRole.manager) &&
              !customer.isAmountPhaseCompleted) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showUpdateAmountDialog(customer);
              },
              child: const Text('Update Amount'),
            ),
            if (customer.amountTotal != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showClearAmountDialog(customer);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Clear Phase'),
              ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showUpdateAmountDialog(CustomerModel customer) {
    final kwController = TextEditingController(
      text:
          customer.amountKw?.toString() ??
          customer.estimatedKw?.toString() ??
          '',
    );
    final totalAmountController = TextEditingController(
      text: customer.amountTotal?.toString() ?? '',
    );
    final paidAmountController = TextEditingController(
      text: customer.amountPaid?.toString() ?? '',
    );
    final utrController = TextEditingController(
      text: customer.amountUtrNumber ?? '',
    );
    final notesController = TextEditingController(
      text: customer.amountNotes ?? '',
    );

    DateTime? paymentDate = customer.amountPaidDate;
    String paymentStatus = customer.amountPaymentStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Update Amount - ${customer.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: kwController,
                  decoration: const InputDecoration(
                    labelText: 'Final kW Capacity *',
                    border: OutlineInputBorder(),
                    suffixText: 'kW',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: totalAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Total Project Amount *',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: paymentStatus,
                  decoration: const InputDecoration(
                    labelText: 'Payment Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('Payment Pending'),
                    ),
                    DropdownMenuItem(
                      value: 'partial',
                      child: Text('Partially Paid'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Fully Paid'),
                    ),
                  ],
                  onChanged: (value) => setState(() => paymentStatus = value!),
                ),
                const SizedBox(height: 16),

                if (paymentStatus != 'pending') ...[
                  TextFormField(
                    controller: paidAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Paid Amount',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: paymentDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => paymentDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 8),
                          Text(
                            paymentDate != null
                                ? DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(paymentDate!)
                                : 'Select payment date',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: utrController,
                    decoration: const InputDecoration(
                      labelText: 'UTR/Reference Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
              onPressed: () async {
                if (kwController.text.trim().isEmpty ||
                    totalAmountController.text.trim().isEmpty) {
                  _showMessage('Please fill in kW capacity and total amount');
                  return;
                }

                Navigator.pop(context);
                await _updateAmountPhase(
                  customer,
                  int.parse(kwController.text.trim()),
                  double.parse(totalAmountController.text.trim()),
                  paidAmountController.text.trim().isNotEmpty
                      ? double.parse(paidAmountController.text.trim())
                      : null,
                  paymentDate,
                  utrController.text.trim().isNotEmpty
                      ? utrController.text.trim()
                      : null,
                  paymentStatus,
                  notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : null,
                );
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAmountDialog(CustomerModel customer) {
    final notesController = TextEditingController();
    bool proceedWithPending = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Clear Amount Phase - ${customer.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer: ${customer.name}\n'
                'Total Amount: ₹${NumberFormat('#,##,###').format(customer.amountTotal)}\n'
                'Payment Status: ${customer.amountPaymentStatusDisplayName}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),

              if (customer.amountPaymentStatus == 'pending')
                CheckboxListTile(
                  title: const Text('Proceed with pending payment'),
                  subtitle: const Text('Customer can pay later'),
                  value: proceedWithPending,
                  onChanged: (value) =>
                      setState(() => proceedWithPending = value ?? false),
                  contentPadding: EdgeInsets.zero,
                ),

              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Add any additional notes...',
                ),
                maxLines: 3,
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
                if (customer.amountPaymentStatus == 'pending' &&
                    !proceedWithPending) {
                  _showMessage(
                    'Payment is pending. Please update payment details or allow proceeding with pending payment.',
                  );
                  return;
                }

                Navigator.pop(context);

                if (proceedWithPending) {
                  await _proceedWithPendingPayment(
                    customer,
                    notesController.text.trim(),
                  );
                } else {
                  await _clearAmountPhase(
                    customer,
                    notesController.text.trim(),
                  );
                }
              },
              child: const Text('Clear Phase'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAmountPhase(
    CustomerModel customer,
    int finalKw,
    double totalAmount,
    double? paidAmount,
    DateTime? paidDate,
    String? utrNumber,
    String paymentStatus,
    String? notes,
  ) async {
    try {
      // Check if amount and kW are already set
      final bool isAmountSet =
          customer.amountTotal != null && customer.amountKw != null;

      if (!isAmountSet) {
        // Set initial amount phase details
        await _customerService.setAmountPhaseDetails(
          customerId: customer.id,
          userId: _currentUser!.id,
          finalKw: finalKw,
          totalAmount: totalAmount,
          notes: notes,
        );

        // If there's a payment amount, add it as the first payment
        if (paidAmount != null &&
            paidAmount > 0 &&
            utrNumber != null &&
            utrNumber.isNotEmpty) {
          await _customerService.addPayment(
            customerId: customer.id,
            userId: _currentUser!.id,
            paymentAmount: paidAmount,
            paymentDate: paidDate ?? DateTime.now(),
            utrNumber: utrNumber,
            notes: notes,
          );
        }
      } else {
        // Amount is already set, only add payment if provided
        if (paidAmount != null &&
            paidAmount > 0 &&
            utrNumber != null &&
            utrNumber.isNotEmpty) {
          await _customerService.addPayment(
            customerId: customer.id,
            userId: _currentUser!.id,
            paymentAmount: paidAmount,
            paymentDate: paidDate ?? DateTime.now(),
            utrNumber: utrNumber,
            notes: notes,
          );
        } else {
          throw Exception(
            'Amount and kW are already set. To add payments, provide payment amount and UTR number.',
          );
        }
      }

      _showMessage('Amount phase updated successfully');
      _loadData();
    } catch (e) {
      _showMessage('Error updating amount phase: $e');
    }
  }

  Future<void> _clearAmountPhase(CustomerModel customer, String? notes) async {
    try {
      await _customerService.clearAmountPhase(
        customerId: customer.id,
        clearedById: _currentUser!.id,
        notes: notes,
      );

      _showMessage(
        'Amount phase cleared successfully. Customer moved to material allocation phase.',
      );
      _loadData();
    } catch (e) {
      _showMessage('Error clearing amount phase: $e');
    }
  }

  Future<void> _proceedWithPendingPayment(
    CustomerModel customer,
    String? notes,
  ) async {
    try {
      await _customerService.proceedWithPendingPayment(
        customerId: customer.id,
        authorizedById: _currentUser!.id,
        notes: notes,
      );

      _showMessage(
        'Customer moved to next phase with pending payment. Payment can be cleared later.',
      );
      _loadData();
    } catch (e) {
      _showMessage('Error proceeding with pending payment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amount Phase'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorWeight: 3,
          tabs: [
            Tab(
              text: 'All (${_allAmountPhaseCustomers.length})',
              icon: const Icon(Icons.list),
            ),
            Tab(
              text: 'Pending (${_pendingPaymentCustomers.length})',
              icon: const Icon(Icons.pending_actions),
            ),
            Tab(
              text: 'Partial (${_partialPaymentCustomers.length})',
              icon: const Icon(Icons.payment),
            ),
            Tab(
              text: 'Completed (${_completedPaymentCustomers.length})',
              icon: const Icon(Icons.check_circle),
            ),
          ],
          isScrollable: true,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCustomersList(_allAmountPhaseCustomers),
                _buildCustomersList(_pendingPaymentCustomers),
                _buildCustomersList(_partialPaymentCustomers),
                _buildCustomersList(_completedPaymentCustomers),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
