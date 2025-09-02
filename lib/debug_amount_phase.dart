import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/customer_service.dart';

class DebugAmountPhase extends StatefulWidget {
  const DebugAmountPhase({super.key});

  @override
  State<DebugAmountPhase> createState() => _DebugAmountPhaseState();
}

class _DebugAmountPhaseState extends State<DebugAmountPhase> {
  final _supabase = Supabase.instance.client;
  final CustomerService _customerService = CustomerService();
  List<Map<String, dynamic>> _allCustomers = [];
  List<Map<String, dynamic>> _approvedCustomers = [];
  List<Map<String, dynamic>> _amountPhaseCustomers = [];
  List<Map<String, dynamic>> _approvedInApplicationPhase = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDebugData();
  }

  Future<void> _loadDebugData() async {
    try {
      print('🔍 Starting debug data load...');

      // Get all customers
      final allResponse = await _supabase
          .from('customers')
          .select(
            'id, name, email, phone_number, current_phase, application_status, application_approval_date, amount_kw, amount_total, amount_payment_status',
          )
          .eq('is_active', true)
          .order('created_at', ascending: false);

      _allCustomers = List<Map<String, dynamic>>.from(allResponse);
      print('📊 Total customers: ${_allCustomers.length}');

      // Get approved customers
      final approvedResponse = await _supabase
          .from('customers')
          .select(
            'id, name, email, phone_number, current_phase, application_status, application_approval_date, amount_kw, amount_total, amount_payment_status',
          )
          .eq('is_active', true)
          .eq('application_status', 'approved')
          .order('application_approval_date', ascending: false);

      _approvedCustomers = List<Map<String, dynamic>>.from(approvedResponse);
      print('✅ Approved customers: ${_approvedCustomers.length}');

      // Get amount phase customers
      final amountResponse = await _supabase
          .from('customers')
          .select(
            'id, name, email, phone_number, current_phase, application_status, application_approval_date, amount_kw, amount_total, amount_payment_status',
          )
          .eq('is_active', true)
          .eq('current_phase', 'amount')
          .eq('application_status', 'approved')
          .order('application_approval_date', ascending: false);

      _amountPhaseCustomers = List<Map<String, dynamic>>.from(amountResponse);
      print('💰 Amount phase customers: ${_amountPhaseCustomers.length}');

      // Get approved customers still in application phase (this is the problem!)
      final stuckResponse = await _supabase
          .from('customers')
          .select(
            'id, name, email, phone_number, current_phase, application_status, application_approval_date',
          )
          .eq('is_active', true)
          .eq('application_status', 'approved')
          .eq('current_phase', 'application')
          .order('application_approval_date', ascending: false);

      _approvedInApplicationPhase = List<Map<String, dynamic>>.from(
        stuckResponse,
      );
      print(
        '🚨 Approved customers stuck in application phase: ${_approvedInApplicationPhase.length}',
      );

      // Print detailed info
      print('\n=== ALL CUSTOMERS ===');
      for (var customer in _allCustomers) {
        print(
          '${customer['name']}: phase=${customer['current_phase']}, status=${customer['application_status']}, approved=${customer['application_approval_date']}',
        );
      }

      print('\n=== APPROVED CUSTOMERS ===');
      for (var customer in _approvedCustomers) {
        print(
          '${customer['name']}: phase=${customer['current_phase']}, approved=${customer['application_approval_date']}',
        );
      }

      print('\n=== AMOUNT PHASE CUSTOMERS ===');
      for (var customer in _amountPhaseCustomers) {
        print(
          '${customer['name']}: payment_status=${customer['amount_payment_status']}, amount=${customer['amount_total']}',
        );
      }

      print('\n=== APPROVED CUSTOMERS STUCK IN APPLICATION PHASE ===');
      for (var customer in _approvedInApplicationPhase) {
        print(
          '${customer['name']}: phase=${customer['current_phase']}, status=${customer['application_status']}, approved=${customer['application_approval_date']}',
        );
      }
    } catch (e) {
      print('❌ Error loading debug data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Amount Phase'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    'All Customers',
                    _allCustomers.length.toString(),
                    Icons.people,
                    Colors.blue,
                    _allCustomers,
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    'Approved Applications',
                    _approvedCustomers.length.toString(),
                    Icons.check_circle,
                    Colors.green,
                    _approvedCustomers,
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    'Amount Phase Customers',
                    _amountPhaseCustomers.length.toString(),
                    Icons.payments,
                    Colors.orange,
                    _amountPhaseCustomers,
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    '🚨 Stuck in Application Phase',
                    _approvedInApplicationPhase.length.toString(),
                    Icons.warning,
                    Colors.red,
                    _approvedInApplicationPhase,
                  ),
                  const SizedBox(height: 24),
                  if (_approvedInApplicationPhase.isNotEmpty)
                    _buildMigrationButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard(
    String title,
    String count,
    IconData icon,
    Color color,
    List<Map<String, dynamic>> data,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (data.isEmpty)
              const Text('No data found', style: TextStyle(color: Colors.grey))
            else
              ...data
                  .take(5)
                  .map(
                    (customer) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              customer['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Phase: ${customer['current_phase'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Status: ${customer['application_status'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            if (data.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '... and ${data.length - 5} more',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMigrationButton() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.healing, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Fix Data Issue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Found ${_approvedInApplicationPhase.length} approved applications that are stuck in application phase. Click below to move them to amount phase.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _runMigration,
              icon: const Icon(Icons.auto_fix_high),
              label: Text(
                'Migrate ${_approvedInApplicationPhase.length} Customers to Amount Phase',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runMigration() async {
    try {
      setState(() => _isLoading = true);

      await _customerService.migrateApprovedApplicationsToAmountPhase();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Successfully migrated ${_approvedInApplicationPhase.length} customers to amount phase!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Reload data to see the changes
      await _loadDebugData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Migration failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
