class SubscriptionPlanModel {
  final int id;
  final String code;
  final String name;
  final String badge;
  final String description;
  final String priceDisplay;
  final int durationDays;
  final int maxEvents;
  final int maxStorageMb;
  final bool customQrAllowed;
  final bool guestUploadAllowed;
  final bool businessProfileAllowed;

  SubscriptionPlanModel({
    required this.id,
    required this.code,
    required this.name,
    required this.badge,
    required this.description,
    required this.priceDisplay,
    required this.durationDays,
    required this.maxEvents,
    required this.maxStorageMb,
    required this.customQrAllowed,
    required this.guestUploadAllowed,
    required this.businessProfileAllowed,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      badge: json['badge'] ?? '',
      description: json['description'] ?? '',
      priceDisplay: json['price_display'] ?? '₹${json['price']}',
      durationDays: json['duration_days'] ?? 0,
      maxEvents: json['max_events'] ?? 1,
      maxStorageMb: json['max_storage_mb'] ?? 50,
      customQrAllowed: json['custom_qr_allowed'] ?? false,
      guestUploadAllowed: json['guest_upload_allowed'] ?? false,
      businessProfileAllowed: json['business_profile_allowed'] ?? false,
    );
  }
}
