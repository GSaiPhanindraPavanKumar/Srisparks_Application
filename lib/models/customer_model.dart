class CustomerModel {
  final String id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final String? companyName;
  final String? taxId;
  final bool isActive;
  final String officeId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  CustomerModel({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.companyName,
    this.taxId,
    required this.isActive,
    required this.officeId,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zip_code'],
      country: json['country'],
      companyName: json['company_name'],
      taxId: json['tax_id'],
      isActive: json['is_active'] ?? true,
      officeId: json['office_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
      'company_name': companyName,
      'tax_id': taxId,
      'is_active': isActive,
      'office_id': officeId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  String get fullAddress {
    final parts = [
      address,
      city,
      state,
      zipCode,
      country,
    ].where((part) => part != null && part.isNotEmpty).toList();
    return parts.join(', ');
  }

  String get displayName {
    return companyName?.isNotEmpty == true ? companyName! : name;
  }
}
