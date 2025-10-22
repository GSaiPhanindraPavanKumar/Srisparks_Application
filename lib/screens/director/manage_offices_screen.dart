import 'package:flutter/material.dart';
import '../../models/office_model.dart';
import '../../services/office_service.dart';

class ManageOfficesScreen extends StatefulWidget {
  const ManageOfficesScreen({super.key});

  @override
  State<ManageOfficesScreen> createState() => _ManageOfficesScreenState();
}

class _ManageOfficesScreenState extends State<ManageOfficesScreen> {
  final OfficeService _officeService = OfficeService();

  List<OfficeModel> _offices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOffices();
  }

  Future<void> _loadOffices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _offices = await _officeService.getAllOffices();
    } catch (e) {
      _showMessage('Error loading offices: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddOfficeDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final zipController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Office'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Office Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stateController,
                decoration: const InputDecoration(
                  labelText: 'State *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: zipController,
                decoration: const InputDecoration(
                  labelText: 'ZIP Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
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
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  addressController.text.trim().isEmpty ||
                  cityController.text.trim().isEmpty ||
                  stateController.text.trim().isEmpty) {
                _showMessage('Please fill in all required fields');
                return;
              }

              try {
                await _officeService.createOffice(
                  name: nameController.text.trim(),
                  address: addressController.text.trim(),
                  city: cityController.text.trim(),
                  state: stateController.text.trim(),
                  zipCode: zipController.text.trim().isEmpty
                      ? null
                      : zipController.text.trim(),
                  phoneNumber: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                  email: emailController.text.trim().isEmpty
                      ? null
                      : emailController.text.trim(),
                );

                Navigator.pop(context);
                _showMessage('Office added successfully');
                _loadOffices();
              } catch (e) {
                _showMessage('Error adding office: $e');
              }
            },
            child: const Text('Add Office'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Offices'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOffices),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offices.isEmpty
          ? const Center(
              child: Text(
                'No offices found',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _offices.length,
              itemBuilder: (context, index) {
                final office = _offices[index];
                return _buildOfficeCard(office);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOfficeDialog,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildOfficeCard(OfficeModel office) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_city, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    office.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: office.isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    office.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: office.isActive ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${office.address}, ${office.city}, ${office.state}${office.zipCode != null ? ' ${office.zipCode}' : ''}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),

            if (office.phoneNumber != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    office.phoneNumber!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],

            if (office.email != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.email, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    office.email!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showOfficeDetails(office),
                  icon: const Icon(Icons.info),
                  label: const Text('Details'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _showMessage('Office management features coming soon');
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOfficeDetails(OfficeModel office) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(office.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Address', '${office.address}'),
            _buildDetailRow('City', office.city ?? 'Not specified'),
            _buildDetailRow('State', office.state ?? 'Not specified'),
            if (office.zipCode != null)
              _buildDetailRow('ZIP Code', office.zipCode!),
            if (office.phoneNumber != null)
              _buildDetailRow('Phone', office.phoneNumber!),
            if (office.email != null) _buildDetailRow('Email', office.email!),
            _buildDetailRow('Status', office.isActive ? 'Active' : 'Inactive'),
            _buildDetailRow(
              'Created',
              office.createdAt.toLocal().toString().split(' ')[0],
            ),
          ],
        ),
        actions: [
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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
}
