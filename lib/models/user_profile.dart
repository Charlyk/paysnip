/// Represents a user profile with payment information and scan limits
class UserProfile {
  final String id;
  final String? venmoUsername;
  final String? paypalEmail;
  final int scanCount;
  final DateTime scanResetDate;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    this.venmoUsername,
    this.paypalEmail,
    required this.scanCount,
    required this.scanResetDate,
    this.isPremium = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Supabase JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      venmoUsername: json['venmo_username'] as String?,
      paypalEmail: json['paypal_email'] as String?,
      scanCount: json['scan_count'] as int? ?? 0,
      scanResetDate: DateTime.parse(json['scan_reset_date'] as String),
      isPremium: json['is_premium'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venmo_username': venmoUsername,
      'paypal_email': paypalEmail,
      'scan_count': scanCount,
      'scan_reset_date': scanResetDate.toIso8601String(),
      'is_premium': isPremium,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with optional modifications
  UserProfile copyWith({
    String? id,
    String? venmoUsername,
    String? paypalEmail,
    int? scanCount,
    DateTime? scanResetDate,
    bool? isPremium,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      venmoUsername: venmoUsername ?? this.venmoUsername,
      paypalEmail: paypalEmail ?? this.paypalEmail,
      scanCount: scanCount ?? this.scanCount,
      scanResetDate: scanResetDate ?? this.scanResetDate,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user has payment info set up
  bool get hasPaymentInfo =>
      (venmoUsername != null && venmoUsername!.isNotEmpty) ||
      (paypalEmail != null && paypalEmail!.isNotEmpty);

  /// Get display name for payment method
  String? get paymentDisplay =>
      venmoUsername ?? paypalEmail ?? 'No payment info';
}
