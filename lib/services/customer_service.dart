import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_model.dart';
import '../models/activity_log_model.dart';

class CustomerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all customers for an office
  Future<List<CustomerModel>> getCustomersByOffice(String officeId) async {
    final response = await _supabase
        .from('customers')
        .select()
        .eq('office_id', officeId)
        .eq('is_active', true)
        .order('name', ascending: true);

    return (response as List)
        .map((customer) => CustomerModel.fromJson(customer))
        .toList();
  }

  // Get all customers across all offices (for directors)
  Future<List<CustomerModel>> getAllCustomers() async {
    final response = await _supabase
        .from('customers')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((customer) => CustomerModel.fromJson(customer))
        .toList();
  }

  // Get customer by ID
  Future<CustomerModel?> getCustomerById(String customerId) async {
    final response = await _supabase
        .from('customers')
        .select()
        .eq('id', customerId)
        .single();

    return CustomerModel.fromJson(response);
  }

  // Search customers
  Future<List<CustomerModel>> searchCustomers(
    String query,
    String officeId,
  ) async {
    final response = await _supabase
        .from('customers')
        .select()
        .eq('office_id', officeId)
        .eq('is_active', true)
        .or(
          'name.ilike.%$query%,email.ilike.%$query%,phone_number.ilike.%$query%,electric_meter_service_number.ilike.%$query%',
        )
        .order('name', ascending: true);

    return (response as List)
        .map((customer) => CustomerModel.fromJson(customer))
        .toList();
  }

  // Create new customer
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    final customerData = customer.toJson();
    customerData.remove('id'); // Remove ID to let the database generate it
    customerData['created_at'] = DateTime.now().toIso8601String();

    final response = await _supabase
        .from('customers')
        .insert(customerData)
        .select()
        .single();

    final createdCustomer = CustomerModel.fromJson(response);

    // Log the activity
    await _logActivity(
      activityType: ActivityType.customer_created,
      description: 'Customer created: ${customer.name}',
      entityId: createdCustomer.id,
      entityType: 'customer',
      newData: customerData,
    );

    return createdCustomer;
  }

  // Create new customer (legacy method for backward compatibility)
  Future<CustomerModel> createCustomerLegacy({
    required String name,
    String? email,
    String? phoneNumber,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    double? latitude,
    double? longitude,
    int? kw,
    String? electricMeterServiceNumber,
    required String officeId,
    required String addedById,
  }) async {
    final customerData = {
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'kw': kw,
      'electric_meter_service_number': electricMeterServiceNumber,
      'is_active': true,
      'office_id': officeId,
      'added_by_id': addedById,
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('customers')
        .insert(customerData)
        .select()
        .single();

    final customer = CustomerModel.fromJson(response);

    // Log the activity
    await _logActivity(
      activityType: ActivityType.customer_created,
      description: 'Customer created: $name',
      entityId: customer.id,
      entityType: 'customer',
      newData: customerData,
    );

    return customer;
  }

  // Update customer
  Future<CustomerModel> updateCustomer(
    String customerId,
    Map<String, dynamic> updates,
  ) async {
    // Get old data for logging
    final oldCustomer = await getCustomerById(customerId);

    final response = await _supabase
        .from('customers')
        .update(updates)
        .eq('id', customerId)
        .select()
        .single();

    final customer = CustomerModel.fromJson(response);

    // Log the activity
    await _logActivity(
      activityType: ActivityType.customer_updated,
      description: 'Customer updated: ${customer.name}',
      entityId: customerId,
      entityType: 'customer',
      oldData: oldCustomer?.toJson(),
      newData: updates,
    );

    return customer;
  }

  // Deactivate customer
  Future<CustomerModel> deactivateCustomer(String customerId) async {
    final response = await _supabase
        .from('customers')
        .update({'is_active': false})
        .eq('id', customerId)
        .select()
        .single();

    return CustomerModel.fromJson(response);
  }

  // Activate customer
  Future<CustomerModel> activateCustomer(String customerId) async {
    final response = await _supabase
        .from('customers')
        .update({'is_active': true})
        .eq('id', customerId)
        .select()
        .single();

    return CustomerModel.fromJson(response);
  }

  // Get customer statistics
  Future<Map<String, dynamic>> getCustomerStatistics(String officeId) async {
    final response = await _supabase
        .from('customers')
        .select('is_active')
        .eq('office_id', officeId);

    int totalCustomers = response.length;
    int activeCustomers = response.where((c) => c['is_active'] == true).length;
    int inactiveCustomers = totalCustomers - activeCustomers;

    return {
      'total_customers': totalCustomers,
      'active_customers': activeCustomers,
      'inactive_customers': inactiveCustomers,
    };
  }

  // Get recently added customers
  Future<List<CustomerModel>> getRecentCustomers(
    String officeId, {
    int limit = 10,
  }) async {
    final response = await _supabase
        .from('customers')
        .select()
        .eq('office_id', officeId)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((customer) => CustomerModel.fromJson(customer))
        .toList();
  }

  // Application Phase Methods

  // Get customers in application phase
  Future<List<CustomerModel>> getApplicationPhaseCustomers(
    String officeId,
  ) async {
    final response = await _supabase
        .from('customers')
        .select()
        .eq('office_id', officeId)
        .eq('current_phase', 'application')
        .eq('is_active', true)
        .order('application_date', ascending: false);

    return (response as List)
        .map((customer) => CustomerModel.fromJson(customer))
        .toList();
  }

  // Get customers by application status
  Future<List<CustomerModel>> getCustomersByApplicationStatus(
    String officeId,
    String status,
  ) async {
    final response = await _supabase
        .from('customers')
        .select()
        .eq('office_id', officeId)
        .eq('current_phase', 'application')
        .eq('application_status', status)
        .eq('is_active', true)
        .order('application_date', ascending: false);

    return (response as List)
        .map((customer) => CustomerModel.fromJson(customer))
        .toList();
  }

  // Get all applications across all offices (for directors)
  Future<List<CustomerModel>> getAllApplications() async {
    final response = await _supabase
        .from('customers')
        .select()
        .eq('current_phase', 'application')
        .eq('is_active', true)
        .order('application_date', ascending: false);

    return (response as List)
        .map((customer) => CustomerModel.fromJson(customer))
        .toList();
  }

  // Get all applications by status across all offices (for directors)
  Future<List<CustomerModel>> getAllApplicationsByStatus(String status) async {
    final response = await _supabase
        .from('customers')
        .select()
        .eq('current_phase', 'application')
        .eq('application_status', status)
        .eq('is_active', true)
        .order('application_date', ascending: false);

    return (response as List)
        .map((customer) => CustomerModel.fromJson(customer))
        .toList();
  }

  // Approve application
  Future<CustomerModel> approveApplication(
    String customerId,
    String approverId,
  ) async {
    final updates = {
      'application_status': 'approved',
      'application_approved_by_id': approverId,
      'application_approval_date': DateTime.now().toIso8601String(),
      'current_phase': 'amount', // Move to amount phase after approval
    };

    final response = await _supabase
        .from('customers')
        .update(updates)
        .eq('id', customerId)
        .select()
        .single();

    final customer = CustomerModel.fromJson(response);

    // Log the activity
    await _logActivity(
      activityType: ActivityType.application_approved,
      description:
          'Application approved for customer: ${customer.name}. Moved to amount phase.',
      entityId: customerId,
      entityType: 'customer',
      newData: updates,
    );

    return customer;
  }

  // Reject application
  Future<CustomerModel> rejectApplication(
    String customerId,
    String rejectedById,
    String? rejectionReason,
  ) async {
    final updates = {
      'application_status': 'rejected',
      'application_approved_by_id':
          rejectedById, // Use same field for consistency
      'application_approval_date': DateTime.now().toIso8601String(),
      'application_notes': rejectionReason, // Use application_notes field
    };

    final response = await _supabase
        .from('customers')
        .update(updates)
        .eq('id', customerId)
        .select()
        .single();

    final customer = CustomerModel.fromJson(response);

    // Log the activity
    await _logActivity(
      activityType: ActivityType.application_rejected,
      description: 'Application rejected for customer: ${customer.name}',
      entityId: customerId,
      entityType: 'customer',
      newData: updates,
    );

    return customer;
  }

  // Manager recommendation methods
  Future<CustomerModel> recommendApplication(
    String customerId,
    String managerId,
    String recommendation, // 'approve' or 'reject'
    String? comment,
  ) async {
    final updates = {
      'manager_recommendation': recommendation,
      'manager_recommended_by_id': managerId,
      'manager_recommendation_date': DateTime.now().toIso8601String(),
      'manager_recommendation_comment': comment,
    };

    final response = await _supabase
        .from('customers')
        .update(updates)
        .eq('id', customerId)
        .select()
        .single();

    final customer = CustomerModel.fromJson(response);

    // Log the activity
    await _logActivity(
      activityType: recommendation == 'approve'
          ? ActivityType.application_recommended
          : ActivityType.application_not_recommended,
      description:
          'Manager ${recommendation == 'approve' ? 'recommended' : 'not recommended'} application for customer: ${customer.name}',
      entityId: customerId,
      entityType: 'customer',
      newData: updates,
    );

    return customer;
  }

  // Complete site survey
  Future<CustomerModel> completeSiteSurvey(
    String customerId,
    String surveyedById,
    Map<String, dynamic> surveyData,
  ) async {
    // Extract survey date from surveyData if provided, otherwise use current time
    final surveyDate =
        surveyData['survey_date'] ?? DateTime.now().toIso8601String();

    final updates = {
      'site_survey_completed': true,
      'site_survey_technician_id': surveyedById,
      'site_survey_date': surveyDate,
      'application_details': surveyData,
    };

    final response = await _supabase
        .from('customers')
        .update(updates)
        .eq('id', customerId)
        .select()
        .single();

    final customer = CustomerModel.fromJson(response);

    // Log the activity
    await _logActivity(
      activityType: ActivityType.site_survey_completed,
      description: 'Site survey completed for customer: ${customer.name}',
      entityId: customerId,
      entityType: 'customer',
      newData: updates,
    );

    return customer;
  }

  // Update feasibility status
  Future<CustomerModel> updateFeasibilityStatus(
    String customerId,
    String feasibilityStatus,
    String? feasibilityNotes,
  ) async {
    final updates = {
      'feasibility_status': feasibilityStatus,
      'feasibility_notes': feasibilityNotes,
      'feasibility_date': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('customers')
        .update(updates)
        .eq('id', customerId)
        .select()
        .single();

    final customer = CustomerModel.fromJson(response);

    // Log the activity
    await _logActivity(
      activityType: ActivityType.feasibility_updated,
      description: 'Feasibility status updated for customer: ${customer.name}',
      entityId: customerId,
      entityType: 'customer',
      newData: updates,
    );

    return customer;
  }

  // Move to next phase
  Future<CustomerModel> moveToNextPhase(
    String customerId,
    String nextPhase,
  ) async {
    final updates = {
      'current_phase': nextPhase,
      'phase_updated_date': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('customers')
        .update(updates)
        .eq('id', customerId)
        .select()
        .single();

    final customer = CustomerModel.fromJson(response);

    // Log the activity
    await _logActivity(
      activityType: ActivityType.phase_updated,
      description: 'Customer moved to $nextPhase phase: ${customer.name}',
      entityId: customerId,
      entityType: 'customer',
      newData: updates,
    );

    return customer;
  }

  // Search applications
  Future<List<CustomerModel>> searchApplications(
    String query,
    String officeId,
  ) async {
    final response = await _supabase
        .from('customers')
        .select()
        .eq('office_id', officeId)
        .eq('current_phase', 'application')
        .eq('is_active', true)
        .or(
          'name.ilike.%$query%,email.ilike.%$query%,phone_number.ilike.%$query%,electric_meter_service_number.ilike.%$query%',
        )
        .order('application_date', ascending: false);

    return (response as List)
        .map((customer) => CustomerModel.fromJson(customer))
        .toList();
  }

  // AMOUNT PHASE METHODS

  // Set initial amount phase details (one-time only)
  Future<CustomerModel> setAmountPhaseDetails({
    required String customerId,
    required String userId,
    required int finalKw,
    required double totalAmount,
    String? notes,
  }) async {
    // First check if amount and kW are already set
    final existing = await getCustomerById(customerId);
    if (existing != null &&
        existing.amountTotal != null &&
        existing.amountKw != null) {
      throw Exception('Amount and kW cannot be modified once set');
    }

    final updates = {
      'kw': finalKw, // Store final kW in existing kw column
      'amount_kw': finalKw, // Also store in amount_kw for amount phase tracking
      'amount_total': totalAmount,
      'amount_payments_data': '[]', // Initialize empty payment history
      'amount_payment_status': 'pending',
      'amount_notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('customers')
        .update(updates)
        .eq('id', customerId)
        .select()
        .single();

    await _logActivity(
      activityType: ActivityType.customer_updated,
      description: 'Amount phase details set for customer',
      entityId: customerId,
      entityType: 'customer',
      newData: updates,
    );

    return CustomerModel.fromJson(response);
  }

  // Add a new payment to the customer
  Future<CustomerModel> addPayment({
    required String customerId,
    required String userId,
    required double paymentAmount,
    required DateTime paymentDate,
    required String utrNumber,
    String? notes,
  }) async {
    // Get current customer data
    final customer = await getCustomerById(customerId);
    if (customer == null) {
      throw Exception('Customer not found');
    }

    // Validate that total amount is set
    if (customer.amountTotal == null || customer.amountTotal! <= 0) {
      throw Exception('Total amount must be set before adding payments');
    }

    // Parse existing payments
    List<Map<String, dynamic>> payments = customer.paymentHistory;

    // Calculate current total paid
    double currentPaid = customer.totalAmountPaid;

    // Validate that new payment doesn't exceed total amount
    if (currentPaid + paymentAmount > customer.amountTotal!) {
      throw Exception(
        'Payment amount (₹${paymentAmount.toStringAsFixed(2)}) would exceed total amount. '
        'Remaining: ₹${(customer.amountTotal! - currentPaid).toStringAsFixed(2)}',
      );
    }

    // Add new payment
    final newPayment = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'amount': paymentAmount,
      'date': paymentDate.toIso8601String(),
      'utr_number': utrNumber,
      'notes': notes,
      'added_by_id': userId,
      'added_at': DateTime.now().toIso8601String(),
    };

    payments.add(newPayment);

    // Calculate new totals
    double newTotalPaid = currentPaid + paymentAmount;
    String newPaymentStatus = 'partial';
    String? newCurrentPhase = customer.currentPhase;

    if (newTotalPaid >= customer.amountTotal!) {
      newPaymentStatus = 'completed';
      // Auto-move to next phase when payment is completed
      if (customer.currentPhase == 'amount') {
        newCurrentPhase = 'material_allocation';
      }
    } else if (newTotalPaid > 0) {
      newPaymentStatus = 'partial';
    } else {
      newPaymentStatus = 'pending';
    }

    // Update database
    final updates = {
      'amount_payments_data': jsonEncode(payments),
      'amount_payment_status': newPaymentStatus,
      'amount_paid': newTotalPaid, // Update legacy field for compatibility
      'amount_paid_date': paymentDate.toIso8601String(), // Latest payment date
      'amount_utr_number': utrNumber, // Latest UTR
      'updated_at': DateTime.now().toIso8601String(),
    };

    // If payment is completed, auto-move phase
    if (newCurrentPhase != customer.currentPhase) {
      updates['current_phase'] = newCurrentPhase;
    }

    final response = await _supabase
        .from('customers')
        .update(updates)
        .eq('id', customerId)
        .select()
        .single();

    await _logActivity(
      activityType: ActivityType.customer_updated,
      description:
          'Payment of ₹${paymentAmount.toStringAsFixed(2)} added. '
          'Status: $newPaymentStatus${newCurrentPhase != customer.currentPhase ? '. Moved to $newCurrentPhase phase.' : ''}',
      entityId: customerId,
      entityType: 'customer',
      newData: updates,
    );

    return CustomerModel.fromJson(response);
  }

  // Clear amount phase (only for directors and managers)
  Future<CustomerModel> clearAmountPhase({
    required String customerId,
    required String clearedById,
    String? notes,
  }) async {
    final updates = {
      'amount_cleared_by_id': clearedById,
      'amount_cleared_date': DateTime.now().toIso8601String(),
      'current_phase': 'material_allocation', // Move to next phase
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (notes != null) {
      updates['amount_notes'] = notes;
    }

    final response = await _supabase
        .from('customers')
        .update(updates)
        .eq('id', customerId)
        .select()
        .single();

    await _logActivity(
      activityType: ActivityType.phase_updated,
      description:
          'Amount phase cleared and moved to material allocation phase',
      entityId: customerId,
      entityType: 'customer',
      newData: updates,
    );

    return CustomerModel.fromJson(response);
  }

  // Allow proceed to next phase even with pending payment
  Future<CustomerModel> proceedWithPendingPayment({
    required String customerId,
    required String authorizedById,
    String? notes,
  }) async {
    final updates = {
      'current_phase': 'material_allocation', // Move to next phase
      'amount_payment_status': 'pending', // Keep payment as pending
      'amount_notes':
          notes ?? 'Proceeded with pending payment - to be cleared later',
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('customers')
        .update(updates)
        .eq('id', customerId)
        .select()
        .single();

    await _logActivity(
      activityType: ActivityType.phase_updated,
      description: 'Proceeded to next phase with pending payment',
      entityId: customerId,
      entityType: 'customer',
      newData: updates,
    );

    return CustomerModel.fromJson(response);
  }

  // Get customers in amount phase
  Future<List<CustomerModel>> getAmountPhaseCustomers(String officeId) async {
    final response = await _supabase
        .from('customers')
        .select()
        .eq('office_id', officeId)
        .eq('current_phase', 'amount')
        .eq('application_status', 'approved') // Only approved applications
        .eq('is_active', true)
        .order('application_approval_date', ascending: false);

    return (response as List)
        .map((customer) => CustomerModel.fromJson(customer))
        .toList();
  }

  // Get all amount phase customers (for directors)
  Future<List<CustomerModel>> getAllAmountPhaseCustomers() async {
    final response = await _supabase
        .from('customers')
        .select()
        .eq('current_phase', 'amount')
        .eq('application_status', 'approved') // Only approved applications
        .eq('is_active', true)
        .order('application_approval_date', ascending: false);

    return (response as List)
        .map((customer) => CustomerModel.fromJson(customer))
        .toList();
  }

  // Migration: Fix approved applications that are still in application phase
  Future<void> migrateApprovedApplicationsToAmountPhase() async {
    try {
      // Find all customers that are approved but still in application phase
      final response = await _supabase
          .from('customers')
          .select('id, name')
          .eq('application_status', 'approved')
          .eq('current_phase', 'application')
          .eq('is_active', true);

      final customersToMigrate = response as List;

      if (customersToMigrate.isNotEmpty) {
        print(
          '🔄 Migrating ${customersToMigrate.length} approved applications to amount phase...',
        );

        // Update all approved applications to amount phase
        await _supabase
            .from('customers')
            .update({'current_phase': 'amount'})
            .eq('application_status', 'approved')
            .eq('current_phase', 'application')
            .eq('is_active', true);

        print(
          '✅ Successfully migrated ${customersToMigrate.length} customers to amount phase',
        );

        // Log each migration
        for (var customer in customersToMigrate) {
          await _logActivity(
            activityType: ActivityType.application_approved,
            description:
                'Migrated approved application to amount phase: ${customer['name']}',
            entityId: customer['id'],
            entityType: 'customer',
          );
        }
      } else {
        print(
          'ℹ️ No approved applications found in application phase - migration not needed',
        );
      }
    } catch (e) {
      print('❌ Error during migration: $e');
      rethrow;
    }
  }

  // Private method to log activities
  Future<void> _logActivity({
    required ActivityType activityType,
    required String description,
    String? entityId,
    String? entityType,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    await _supabase.from('activity_logs').insert({
      'user_id': currentUser.id,
      'activity_type': activityType.name,
      'description': description,
      'entity_id': entityId,
      'entity_type': entityType,
      'old_data': oldData,
      'new_data': newData,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
