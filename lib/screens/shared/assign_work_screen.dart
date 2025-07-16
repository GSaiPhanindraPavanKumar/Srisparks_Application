import 'package:flutter/material.dart';
import '../../models/work_model.dart';
import '../../models/user_model.dart';
import '../../models/customer_model.dart';
import '../../services/work_service.dart';
import '../../services/user_service.dart';
import '../../services/customer_service.dart';
import '../../services/auth_service.dart';

class AssignWorkScreen extends StatefulWidget {
  const AssignWorkScreen({super.key});

  @override
  State<AssignWorkScreen> createState() => _AssignWorkScreenState();
}

class _AssignWorkScreenState extends State<AssignWorkScreen> {
  final WorkService _workService = WorkService();
  final UserService _userService = UserService();
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedHoursController = TextEditingController();

  List<UserModel> _availableUsers = [];
  List<CustomerModel> _customers = [];
  UserModel? _currentUser;
  UserModel? _selectedUser;
  CustomerModel? _selectedCustomer;
  WorkPriority _selectedPriority = WorkPriority.medium;
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUser = await _authService.getCurrentUserProfile();

      if (_currentUser != null) {
        // Load users that current user can assign work to
        _availableUsers = await _userService.getAssignableUsers();

        // Load customers for the office
        _customers = await _customerService.getCustomersByOffice(
          _currentUser!.officeId!,
        );
      }
    } catch (e) {
      _showMessage('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _assignWork() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUser == null || _selectedCustomer == null) {
      _showMessage('Please select both user and customer');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _workService.createWork(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        customerId: _selectedCustomer!.id,
        assignedToId: _selectedUser!.id,
        priority: _selectedPriority,
        dueDate: _selectedDueDate,
        estimatedHours: double.tryParse(_estimatedHoursController.text),
        officeId: _currentUser!.officeId!,
      );

      _showMessage('Work assigned successfully');
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Error assigning work: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _getAssignableRolesMessage() {
    if (_currentUser == null) return '';

    switch (_currentUser!.role) {
      case UserRole.director:
        return 'As a Director, you can assign work to Managers, Leads, and Employees';
      case UserRole.manager:
        return 'As a Manager, you can assign work to Leads and Employees';
      case UserRole.employee:
        if (_currentUser!.isLead) {
          return 'As a Lead, you can assign work to Employees only';
        }
        return 'Employees cannot assign work to others';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Work'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Work Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Work Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter work title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Assign to User
                    DropdownButtonFormField<UserModel>(
                      value: _selectedUser,
                      decoration: const InputDecoration(
                        labelText: 'Assign to User',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableUsers.map((user) {
                        return DropdownMenuItem(
                          value: user,
                          child: Text(
                            '${user.fullName} (${user.roleDisplayName})',
                          ),
                        );
                      }).toList(),
                      onChanged: (user) {
                        setState(() {
                          _selectedUser = user;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a user';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Role-based assignment info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getAssignableRolesMessage(),
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Customer
                    DropdownButtonFormField<CustomerModel>(
                      value: _selectedCustomer,
                      decoration: const InputDecoration(
                        labelText: 'Customer',
                        border: OutlineInputBorder(),
                      ),
                      items: _customers.map((customer) {
                        return DropdownMenuItem(
                          value: customer,
                          child: Text(customer.name),
                        );
                      }).toList(),
                      onChanged: (customer) {
                        setState(() {
                          _selectedCustomer = customer;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a customer';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Priority
                    DropdownButtonFormField<WorkPriority>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: WorkPriority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(priority.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (priority) {
                        setState(() {
                          _selectedPriority = priority!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Due Date
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 1),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDueDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedDueDate != null
                              ? _selectedDueDate!.toLocal().toString().split(
                                  ' ',
                                )[0]
                              : 'Select due date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Estimated Hours
                    TextFormField(
                      controller: _estimatedHoursController,
                      decoration: const InputDecoration(
                        labelText: 'Estimated Hours (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _assignWork,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Assign Work'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedHoursController.dispose();
    super.dispose();
  }
}
