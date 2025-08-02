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
  String _searchQuery = '';
  List<OfficeModel> _filteredOffices = [];

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
      _filteredOffices = _offices;
    } catch (e) {
      _showMessage('Error loading offices: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterOffices() {
    setState(() {
      final query = _searchQuery.toLowerCase();
      _filteredOffices = _offices.where((office) {
        return office.name.toLowerCase().contains(query) ||
            (office.city?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
            if (office.latitude != null)
              _buildDetailRow('Latitude', office.latitude!.toString()),
            if (office.longitude != null)
              _buildDetailRow('Longitude', office.longitude!.toString()),
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

  void _showEditOfficeDialog(OfficeModel office) {
    final nameController = TextEditingController(text: office.name);
    final addressController = TextEditingController(text: office.address);
    final cityController = TextEditingController(text: office.city);
    final stateController = TextEditingController(text: office.state);
    final zipController = TextEditingController(text: office.zipCode ?? '');
    final phoneController = TextEditingController(
      text: office.phoneNumber ?? '',
    );
    final emailController = TextEditingController(text: office.email ?? '');
    final latitudeController = TextEditingController(
      text: office.latitude?.toString() ?? '',
    );
    final longitudeController = TextEditingController(
      text: office.longitude?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Office'),
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
              const SizedBox(height: 12),
              TextField(
                controller: latitudeController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: longitudeController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                await _officeService.updateOffice(office.id, {
                  'name': nameController.text.trim(),
                  'address': addressController.text.trim(),
                  'city': cityController.text.trim(),
                  'state': stateController.text.trim(),
                  'zip_code': zipController.text.trim().isEmpty
                      ? null
                      : zipController.text.trim(),
                  'phone_number': phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                  'email': emailController.text.trim().isEmpty
                      ? null
                      : emailController.text.trim(),
                  'latitude': latitudeController.text.trim().isEmpty
                      ? null
                      : double.tryParse(latitudeController.text.trim()),
                  'longitude': longitudeController.text.trim().isEmpty
                      ? null
                      : double.tryParse(longitudeController.text.trim()),
                });

                Navigator.pop(context);
                _showMessage('Office updated successfully');
                _loadOffices();
              } catch (e) {
                _showMessage('Error updating office: $e');
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showAddOfficeDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final zipController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final latitudeController = TextEditingController();
    final longitudeController = TextEditingController();

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
              const SizedBox(height: 12),
              TextField(
                controller: latitudeController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: longitudeController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  latitude: latitudeController.text.trim().isEmpty
                      ? null
                      : double.tryParse(latitudeController.text.trim()),
                  longitude: longitudeController.text.trim().isEmpty
                      ? null
                      : double.tryParse(longitudeController.text.trim()),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by name or city...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _filterOffices();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOffices.isEmpty
                ? const Center(
                    child: Text(
                      'No offices found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredOffices.length,
                    itemBuilder: (context, index) {
                      final office = _filteredOffices[index];
                      return _buildOfficeCard(office);
                    },
                  ),
          ),
        ],
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
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
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
                OutlinedButton(
                  onPressed: () => _showOfficeDetails(office),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info),
                      SizedBox(width: 4),
                      Text('Details'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showEditOfficeDialog(office),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 4),
                      Text('Edit'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
