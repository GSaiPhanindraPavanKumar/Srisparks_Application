import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../models/office_model.dart';
import '../../services/customer_service.dart';
import '../../services/office_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../widgets/loading_widget.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService();
  final OfficeService _officeService = OfficeService();

  List<CustomerModel> _allCustomers = [];
  List<CustomerModel> _filteredCustomers = [];
  List<OfficeModel> _allOffices = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _selectedOfficeId;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUser = await _authService.getCurrentUserProfile();
      if (_currentUser != null) {
        // If director, load all offices for selection
        if (_currentUser!.role == UserRole.director) {
          _allOffices = await _officeService.getAllOffices();
          if (_allOffices.isNotEmpty) {
            _selectedOfficeId =
                'all_offices'; // Default to all offices for directors
          } else {
            _showMessage('No offices found in the system');
            return;
          }
          // Note: Directors should have office_id = NULL in database
        } else {
          // For non-directors, use their assigned office (must not be NULL)
          if (_currentUser!.officeId != null) {
            _selectedOfficeId = _currentUser!.officeId;
            // Load just this user's office for the dropdown and office name display
            try {
              final userOffice = await _officeService.getOfficeById(
                _currentUser!.officeId!,
              );
              if (userOffice != null) {
                _allOffices = [userOffice];
              } else {
                _showMessage('Error: Could not find user\'s assigned office');
                return;
              }
            } catch (e) {
              _showMessage('Error loading user office: $e');
              return;
            }
          } else {
            _showMessage(
              'Error: User is not assigned to any office. Please contact administrator.',
            );
            return;
          }
        }

        await _loadCustomers();
      }
    } catch (e) {
      _showMessage('Error initializing screen: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCustomers() async {
    if (_selectedOfficeId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedOfficeId == 'all_offices') {
        // For directors viewing all offices, load customers from all offices
        _allCustomers = [];
        for (final office in _allOffices) {
          final officeCustomers = await _customerService.getCustomersByOffice(
            office.id,
          );
          _allCustomers.addAll(officeCustomers);
        }
        // Sort by name for consistent display
        _allCustomers.sort((a, b) => a.name.compareTo(b.name));
      } else {
        // Load customers for a specific office
        _allCustomers = await _customerService.getCustomersByOffice(
          _selectedOfficeId!,
        );
      }

      _filteredCustomers = _allCustomers;
    } catch (e) {
      _showMessage('Error loading customers: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      _searchQuery = query;
      _filteredCustomers = _allCustomers.where((customer) {
        return customer.name.toLowerCase().contains(query.toLowerCase()) ||
            (customer.email?.toLowerCase().contains(query.toLowerCase()) ??
                false) ||
            (customer.city?.toLowerCase().contains(query.toLowerCase()) ??
                false) ||
            (customer.address?.toLowerCase().contains(query.toLowerCase()) ??
                false);
      }).toList();
    });
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final zipCodeController = TextEditingController();
    final countryController = TextEditingController();
    final latitudeController = TextEditingController();
    final longitudeController = TextEditingController();
    final kwController = TextEditingController();
    final serviceNumberController = TextEditingController();

    // For directors, allow office selection within the dialog
    String? selectedOfficeId = _selectedOfficeId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Customer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Office selector for directors
                if (_currentUser?.role == UserRole.director) ...[
                  DropdownButtonFormField<String>(
                    value: selectedOfficeId == 'all_offices'
                        ? null
                        : selectedOfficeId,
                    decoration: const InputDecoration(
                      labelText: 'Select Office *',
                      border: OutlineInputBorder(),
                      hintText: 'Choose an office for the customer',
                    ),
                    items: _allOffices.map((office) {
                      return DropdownMenuItem<String>(
                        value: office.id,
                        child: Row(
                          children: [
                            const Icon(Icons.business, size: 16),
                            const SizedBox(width: 8),
                            Text(office.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedOfficeId = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: stateController,
                        decoration: const InputDecoration(
                          labelText: 'State',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: zipCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Zip Code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: countryController,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. 16.746794',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: longitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. 81.7022911',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: kwController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'KW (Kilowatts)',
                    border: OutlineInputBorder(),
                    hintText: 'Enter power rating',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: serviceNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Service Number',
                    border: OutlineInputBorder(),
                    hintText: 'Electric meter service number',
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
                if (nameController.text.trim().isEmpty) {
                  _showMessage('Please enter customer name');
                  return;
                }

                // For directors, validate office selection
                if (_currentUser?.role == UserRole.director &&
                    (selectedOfficeId == null ||
                        selectedOfficeId == 'all_offices')) {
                  _showMessage(
                    'Please select a specific office for the customer',
                  );
                  return;
                }

                try {
                  final currentUser = await _authService
                      .getCurrentUserProfile();
                  if (currentUser != null) {
                    // Parse numeric fields
                    double? latitude;
                    double? longitude;
                    int? kw;

                    if (latitudeController.text.trim().isNotEmpty) {
                      latitude = double.tryParse(
                        latitudeController.text.trim(),
                      );
                      if (latitude == null) {
                        _showMessage('Please enter a valid latitude');
                        return;
                      }
                    }

                    if (longitudeController.text.trim().isNotEmpty) {
                      longitude = double.tryParse(
                        longitudeController.text.trim(),
                      );
                      if (longitude == null) {
                        _showMessage('Please enter a valid longitude');
                        return;
                      }
                    }

                    if (kwController.text.trim().isNotEmpty) {
                      kw = int.tryParse(kwController.text.trim());
                      if (kw == null) {
                        _showMessage('Please enter a valid KW value');
                        return;
                      }
                    }

                    // Use selectedOfficeId for directors, fallback to user's office for others
                    // Directors have office_id = NULL in database, so they must select an office
                    final targetOfficeId =
                        _currentUser!.role == UserRole.director
                        ? selectedOfficeId!
                        : (selectedOfficeId ?? currentUser.officeId!);

                    await _customerService.createCustomerLegacy(
                      name: nameController.text.trim(),
                      email: emailController.text.trim().isEmpty
                          ? null
                          : emailController.text.trim(),
                      phoneNumber: phoneController.text.trim().isEmpty
                          ? null
                          : phoneController.text.trim(),
                      address: addressController.text.trim().isEmpty
                          ? null
                          : addressController.text.trim(),
                      city: cityController.text.trim().isEmpty
                          ? null
                          : cityController.text.trim(),
                      state: stateController.text.trim().isEmpty
                          ? null
                          : stateController.text.trim(),
                      zipCode: zipCodeController.text.trim().isEmpty
                          ? null
                          : zipCodeController.text.trim(),
                      country: countryController.text.trim().isEmpty
                          ? null
                          : countryController.text.trim(),
                      latitude: latitude,
                      longitude: longitude,
                      kw: kw,
                      electricMeterServiceNumber:
                          serviceNumberController.text.trim().isEmpty
                          ? null
                          : serviceNumberController.text.trim(),
                      officeId: targetOfficeId,
                      addedById: currentUser.id,
                    );

                    Navigator.pop(context);
                    _showMessage('Customer added successfully');
                    _loadCustomers();
                  }
                } catch (e) {
                  _showMessage('Error adding customer: $e');
                }
              },
              child: const Text('Add Customer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Helper method to safely get office display name
  String _getOfficeDisplayName() {
    if (_selectedOfficeId == 'all_offices') {
      return 'All Offices';
    }

    try {
      final office = _allOffices.firstWhere(
        (office) => office.id == _selectedOfficeId,
      );
      return office.name;
    } catch (e) {
      return 'Unknown Office';
    }
  }

  // Helper method to safely get customer's office name
  String _getCustomerOfficeName(String officeId) {
    try {
      final office = _allOffices.firstWhere((office) => office.id == officeId);
      return office.name;
    } catch (e) {
      return 'Unknown Office';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customers'),
            if (_currentUser?.role == UserRole.director &&
                _selectedOfficeId != null)
              Text(
                _getOfficeDisplayName(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Office selector for directors
          if (_currentUser?.role == UserRole.director) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, color: Colors.teal),
                  const SizedBox(width: 8),
                  const Text(
                    'Office:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedOfficeId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        // Add "All Offices" option for directors
                        const DropdownMenuItem<String>(
                          value: 'all_offices',
                          child: Row(
                            children: [
                              Icon(
                                Icons.business_center,
                                size: 16,
                                color: Colors.teal,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'All Offices',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        // Add individual offices
                        ..._allOffices.map((office) {
                          return DropdownMenuItem<String>(
                            value: office.id,
                            child: Row(
                              children: [
                                const Icon(Icons.business, size: 16),
                                const SizedBox(width: 8),
                                Text(office.name),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null && newValue != _selectedOfficeId) {
                          setState(() {
                            _selectedOfficeId = newValue;
                          });
                          _loadCustomers();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: _filterCustomers,
                  decoration: const InputDecoration(
                    labelText: 'Search customers...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                // Show summary for directors viewing all offices
                if (_currentUser?.role == UserRole.director &&
                    _selectedOfficeId == 'all_offices' &&
                    _allCustomers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.teal.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Showing ${_filteredCustomers.length} customers from ${_allOffices.length} offices',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.teal.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Customers list
          Expanded(
            child: _isLoading
                ? const LoadingWidget(
                    message: 'Loading customers...',
                    color: Colors.purple,
                  )
                : _filteredCustomers.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No customers found'
                          : 'No customers match your search',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : PullToRefreshWrapper(
                    onRefresh: _loadCustomers,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = _filteredCustomers[index];
                        return _buildCustomerCard(customer);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCustomerDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal,
          child: Text(
            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show office name for directors viewing all offices
            if (_currentUser?.role == UserRole.director &&
                _selectedOfficeId == 'all_offices')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getCustomerOfficeName(customer.officeId),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.teal.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (customer.email != null)
              Text(customer.email!, style: const TextStyle(color: Colors.grey)),
            if (customer.phoneNumber != null)
              Text(
                customer.phoneNumber!,
                style: const TextStyle(color: Colors.grey),
              ),
            if (customer.city != null && customer.state != null)
              Text(
                '${customer.city}, ${customer.state}',
                style: const TextStyle(color: Colors.grey),
              ),
            if (customer.kw != null)
              Text(
                '${customer.kw} KW',
                style: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              // TODO: Implement edit customer
              _showMessage('Edit customer feature coming soon');
            } else if (value == 'deactivate') {
              _showDeactivateDialog(customer);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')],
              ),
            ),
            PopupMenuItem(
              value: 'deactivate',
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('Deactivate', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showCustomerDetails(customer),
      ),
    );
  }

  void _showCustomerDetails(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show office information for directors
              if (_currentUser?.role == UserRole.director)
                _buildDetailRow(
                  'Office',
                  _getCustomerOfficeName(customer.officeId),
                ),
              if (customer.email != null)
                _buildDetailRow('Email', customer.email!),
              if (customer.phoneNumber != null)
                _buildDetailRow('Phone', customer.phoneNumber!),
              if (customer.address != null)
                _buildDetailRow('Address', customer.address!),
              if (customer.city != null)
                _buildDetailRow('City', customer.city!),
              if (customer.state != null)
                _buildDetailRow('State', customer.state!),
              if (customer.zipCode != null)
                _buildDetailRow('Zip Code', customer.zipCode!),
              if (customer.country != null)
                _buildDetailRow('Country', customer.country!),
              if (customer.latitude != null && customer.longitude != null)
                _buildDetailRow(
                  'Location',
                  '${customer.latitude}, ${customer.longitude}',
                ),
              if (customer.kw != null)
                _buildDetailRow('KW Rating', '${customer.kw} KW'),
              if (customer.electricMeterServiceNumber != null)
                _buildDetailRow(
                  'Service Number',
                  customer.electricMeterServiceNumber!,
                ),
              _buildDetailRow(
                'Status',
                customer.isActive ? 'Active' : 'Inactive',
              ),
            ],
          ),
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

  void _showDeactivateDialog(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Customer'),
        content: Text('Are you sure you want to deactivate ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _customerService.deactivateCustomer(customer.id);
                Navigator.pop(context);
                _showMessage('Customer deactivated');
                _loadCustomers();
              } catch (e) {
                _showMessage('Error deactivating customer: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }
}
