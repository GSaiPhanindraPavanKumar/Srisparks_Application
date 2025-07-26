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
          'name.ilike.%$query%,email.ilike.%$query%,company_name.ilike.%$query%',
        )
        .order('name', ascending: true);

    return (response as List)
        .map((customer) => CustomerModel.fromJson(customer))
        .toList();
  }

  // Create new customer
  Future<CustomerModel> createCustomer({
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
