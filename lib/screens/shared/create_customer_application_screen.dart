import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../services/customer_service.dart';
import '../../services/auth_service.dart';

class CreateCustomerApplicationScreen extends StatefulWidget {
  const CreateCustomerApplicationScreen({super.key});

  @override
  State<CreateCustomerApplicationScreen> createState() =>
      _CreateCustomerApplicationScreenState();
}

class _CreateCustomerApplicationScreenState
    extends State<CreateCustomerApplicationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService();

  late TabController _tabController;

  UserModel? _currentUser;
  bool _isLoading = false;

  // Basic Information
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController();

  // Project Details
  final _estimatedKwController = TextEditingController();
  final _estimatedCostController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _notesController = TextEditingController();
  final _serviceNumberController = TextEditingController();

  // Site Survey Details
  String _roofType = 'concrete';
  String _roofArea = '';
  String _shadingIssues = 'minimal';
  String _electricalCapacity = 'adequate';
  String _customerRequirement = 'grid_tie_system';

  // Site Survey Status - Simplified
  String _siteSurveyStatus = 'pending'; // pending, ongoing, completed
  bool _isCurrentUserDoingSurvey = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUser();

    // Add listener to update UI when tab changes
    _tabController.addListener(() {
      setState(() {});
    });

    // Set default values
    _countryController.text = 'India';
    _stateController.text = 'Andhra Pradesh';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _estimatedKwController.dispose();
    _estimatedCostController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _notesController.dispose();
    _serviceNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await _authService.getCurrentUser();
      setState(() {});
    } catch (e) {
      _showMessage('Error loading user data: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildBasicInformationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Information',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Customer Name *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter customer name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!value.contains('@')) {
                  return 'Please enter a valid email address';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter city';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'State *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter state';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _zipCodeController,
                  decoration: const InputDecoration(
                    labelText: 'ZIP Code',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(
                    labelText: 'Country *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter country';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Details',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _estimatedKwController,
                  decoration: const InputDecoration(
                    labelText: 'Estimated Capacity (kW) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.solar_power),
                    suffix: Text('kW'),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter estimated capacity';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _estimatedCostController,
                  decoration: const InputDecoration(
                    labelText: 'Estimated Cost (₹)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Site Location (Optional)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latitudeController,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _longitudeController,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement GPS location fetching
              _showMessage('GPS location feature coming soon');
            },
            icon: const Icon(Icons.gps_fixed),
            label: const Text('Get Current Location'),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Additional Notes',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _serviceNumberController,
            decoration: const InputDecoration(
              labelText: 'Electric Meter Service Number *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.electrical_services),
              helperText: 'Enter the electric meter service number',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the electric meter service number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSiteSurveyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Site Survey Details',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Site Survey Status Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Site Survey Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _siteSurveyStatus,
                  decoration: const InputDecoration(
                    labelText: 'Site Survey Status *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.assignment),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('Pending (Survey needed)'),
                    ),
                    DropdownMenuItem(
                      value: 'ongoing',
                      child: Text('Ongoing (In progress)'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _siteSurveyStatus = value!;
                    _isCurrentUserDoingSurvey =
                        false; // Reset when status changes
                  }),
                ),

                if (_siteSurveyStatus == 'ongoing' ||
                    _siteSurveyStatus == 'completed') ...[
                  const SizedBox(height: 16),

                  CheckboxListTile(
                    title: Text(
                      _siteSurveyStatus == 'completed'
                          ? 'Did you complete this survey?'
                          : 'Are you doing this survey?',
                    ),
                    value: _isCurrentUserDoingSurvey,
                    onChanged: (value) => setState(() {
                      _isCurrentUserDoingSurvey = value ?? false;
                    }),
                    contentPadding: EdgeInsets.zero,
                  ),

                  if (!_isCurrentUserDoingSurvey) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Colors.orange.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Survey will be assigned to someone else. Application will show as "Survey Pending" until completed.',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Only show detailed survey fields if status is ongoing or completed
          if (_siteSurveyStatus == 'ongoing' ||
              _siteSurveyStatus == 'completed') ...[
            Text(
              'Survey Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _roofType,
              decoration: const InputDecoration(
                labelText: 'Roof Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'concrete', child: Text('Concrete')),
                DropdownMenuItem(value: 'metal', child: Text('Metal')),
                DropdownMenuItem(value: 'tile', child: Text('Tile')),
                DropdownMenuItem(value: 'asbestos', child: Text('Asbestos')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _roofType = value!),
            ),
            const SizedBox(height: 16),

            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Roof Area (sq ft)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _roofArea = value,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _shadingIssues,
              decoration: const InputDecoration(
                labelText: 'Shading Issues',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'minimal', child: Text('Minimal')),
                DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                DropdownMenuItem(
                  value: 'significant',
                  child: Text('Significant'),
                ),
                DropdownMenuItem(value: 'severe', child: Text('Severe')),
              ],
              onChanged: (value) => setState(() => _shadingIssues = value!),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _electricalCapacity,
              decoration: const InputDecoration(
                labelText: 'Electrical Infrastructure',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'adequate', child: Text('Adequate')),
                DropdownMenuItem(
                  value: 'upgrade_needed',
                  child: Text('Upgrade Needed'),
                ),
                DropdownMenuItem(
                  value: 'insufficient',
                  child: Text('Insufficient'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _electricalCapacity = value!),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _customerRequirement,
              decoration: const InputDecoration(
                labelText: 'System Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'grid_tie_system',
                  child: Text('Grid-Tie System'),
                ),
                DropdownMenuItem(
                  value: 'off_grid_system',
                  child: Text('Off-Grid System'),
                ),
                DropdownMenuItem(
                  value: 'hybrid_system',
                  child: Text('Hybrid System'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _customerRequirement = value!),
            ),
            const SizedBox(height: 20),

            Text(
              'Site Photos',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Photo upload functionality will be available in the next update.',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ] else ...[
            // Show message for pending surveys
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Site survey is pending. Detailed survey information will be collected when the survey begins.',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitApplication() async {
    // First validate the form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Then check all required fields comprehensively
    if (!_validateAllRequiredFields()) {
      return;
    }

    if (_currentUser == null) {
      _showMessage('Error: User not logged in');
      return;
    }

    // Check if user has office assignment (directors might not have office_id)
    String? targetOfficeId;
    if (_currentUser!.role == UserRole.director) {
      // For directors, we need to get the office from somewhere
      // For now, let's show an error since directors should create applications through office selection
      _showMessage(
        'Directors should create applications through the customer management screen',
      );
      return;
    } else {
      // For managers and employees, use their assigned office
      if (_currentUser!.officeId == null) {
        _showMessage(
          'Error: User is not assigned to any office. Please contact administrator.',
        );
        return;
      }
      targetOfficeId = _currentUser!.officeId!;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare application details - only include site survey details if survey is not pending
      final applicationDetails = <String, dynamic>{};

      // Only include site survey details if survey is ongoing or completed
      if (_siteSurveyStatus != 'pending') {
        applicationDetails.addAll({
          'roof_type': _roofType,
          'roof_area': _roofArea,
          'shading_issues': _shadingIssues,
          'electrical_capacity': _electricalCapacity,
          'customer_requirements': _customerRequirement,
        });
      }

      // Create customer application
      final customer = CustomerModel(
        id: '', // Will be generated by the database
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        zipCode: _zipCodeController.text.trim().isEmpty
            ? null
            : _zipCodeController.text.trim(),
        country: _countryController.text.trim(),
        isActive: true,
        officeId: targetOfficeId,
        addedById: _currentUser!.id,
        latitude: _latitudeController.text.trim().isEmpty
            ? null
            : double.tryParse(_latitudeController.text.trim()),
        longitude: _longitudeController.text.trim().isEmpty
            ? null
            : double.tryParse(_longitudeController.text.trim()),
        createdAt: DateTime.now(),

        // Application Phase specific fields
        currentPhase: 'application',
        applicationDate: DateTime.now(),
        applicationDetails: applicationDetails,
        applicationStatus: 'pending',
        siteSurveyCompleted: _siteSurveyStatus == 'completed',
        siteSurveyTechnicianId:
            (_siteSurveyStatus != 'pending' && _isCurrentUserDoingSurvey)
            ? _currentUser!.id
            : null,
        siteSurveyDate: _siteSurveyStatus == 'completed'
            ? DateTime.now()
            : null,
        estimatedKw: int.tryParse(_estimatedKwController.text.trim()),
        estimatedCost: double.tryParse(_estimatedCostController.text.trim()),
        feasibilityStatus: _siteSurveyStatus == 'completed'
            ? 'pending'
            : 'pending',
        electricMeterServiceNumber: _serviceNumberController.text.trim(),
      );

      await _customerService.createCustomer(customer);

      if (mounted) {
        _showMessage('Application submitted successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error submitting application: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validateCurrentTab() {
    switch (_tabController.index) {
      case 0: // Customer Information
        return _nameController.text.trim().isNotEmpty &&
            _phoneController.text.trim().isNotEmpty &&
            _addressController.text.trim().isNotEmpty &&
            _cityController.text.trim().isNotEmpty &&
            _stateController.text.trim().isNotEmpty &&
            _countryController.text.trim().isNotEmpty;
      case 1: // Project Details
        return _estimatedKwController.text.trim().isNotEmpty &&
            _serviceNumberController.text.trim().isNotEmpty;
      case 2: // Site Survey
        // No validation needed - any status is acceptable
        // If pending, survey will be done later by anyone
        // If ongoing/completed without current user, it will show as "Survey Pending"
        return true;
      default:
        return true;
    }
  }

  bool _validateAllRequiredFields() {
    List<String> missingFields = [];

    // Customer Information validation
    if (_nameController.text.trim().isEmpty) {
      missingFields.add('Customer Name');
    }
    if (_phoneController.text.trim().isEmpty) {
      missingFields.add('Phone Number');
    }
    if (_addressController.text.trim().isEmpty) {
      missingFields.add('Address');
    }
    if (_cityController.text.trim().isEmpty) {
      missingFields.add('City');
    }
    if (_stateController.text.trim().isEmpty) {
      missingFields.add('State');
    }
    if (_countryController.text.trim().isEmpty) {
      missingFields.add('Country');
    }

    // Project Details validation
    if (_estimatedKwController.text.trim().isEmpty) {
      missingFields.add('Estimated Capacity (kW)');
    }
    if (_serviceNumberController.text.trim().isEmpty) {
      missingFields.add('Electric Meter Service Number');
    }

    if (missingFields.isNotEmpty) {
      _showMessage(
        'Please fill in all required fields:\n• ${missingFields.join('\n• ')}',
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Customer Application'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Customer'),
            Tab(icon: Icon(Icons.solar_power), text: 'Project'),
            Tab(icon: Icon(Icons.assessment), text: 'Site Survey'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicInformationTab(),
            _buildProjectDetailsTab(),
            _buildSiteSurveyTab(),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_tabController.index > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              final previousIndex = _tabController.index - 1;
                              if (previousIndex >= 0) {
                                _tabController.animateTo(previousIndex);
                              }
                            },
                      child: const Text('Previous'),
                    ),
                  ),
                if (_tabController.index > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_tabController.index ==
                              (_tabController.length - 1)) // Last tab check
                        ? _submitApplication
                        : () {
                            // Validate current tab before proceeding
                            if (_validateCurrentTab()) {
                              final nextIndex = _tabController.index + 1;
                              if (nextIndex < _tabController.length) {
                                _tabController.animateTo(nextIndex);
                              }
                            } else {
                              // Show validation error
                              String message = '';
                              switch (_tabController.index) {
                                case 0:
                                  message =
                                      'Please fill in all required customer information fields';
                                  break;
                                case 1:
                                  message =
                                      'Please enter the estimated capacity (kW) and service number';
                                  break;
                                case 2:
                                  message =
                                      'Please select the site survey status';
                                  break;
                                default:
                                  message = 'Please complete the current tab';
                              }
                              _showMessage(message);
                            }
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                            (_tabController.index ==
                                    (_tabController.length - 1))
                                ? 'Submit Application'
                                : 'Next',
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
