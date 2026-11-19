class BookingModel {
  final String id;
  final int businessId;
  final String businessName;
  final String businessCategory;
  final String? serviceName;
  final double? servicePrice;
  final String date;
  final String timeSlot;
  final int guestsCount;
  final String status; // 'confirmed', 'completed', 'cancelled', 'rescheduled'
  final String? specialRequests;
  final String customerName;
  final String customerPhone;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.businessCategory,
    this.serviceName,
    this.servicePrice,
    required this.date,
    required this.timeSlot,
    this.guestsCount = 2,
    this.status = 'confirmed',
    this.specialRequests,
    required this.customerName,
    required this.customerPhone,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id'] is int ? json['business_id'] : int.tryParse(json['business_id']?.toString() ?? '0') ?? 0,
      businessName: json['business_name'] ?? 'Partner Service',
      businessCategory: json['business_category'] ?? 'General',
      serviceName: json['service_name'],
      servicePrice: json['service_price'] != null ? (double.tryParse(json['service_price'].toString()) ?? 0.0) : null,
      date: json['date'] ?? '',
      timeSlot: json['time_slot'] ?? '',
      guestsCount: json['guests_count'] ?? 2,
      status: json['status'] ?? 'confirmed',
      specialRequests: json['special_requests'],
      customerName: json['customer_name'] ?? 'Guest',
      customerPhone: json['customer_phone'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'business_name': businessName,
      'business_category': businessCategory,
      'service_name': serviceName,
      'service_price': servicePrice,
      'date': date,
      'time_slot': timeSlot,
      'guests_count': guestsCount,
      'status': status,
      'special_requests': specialRequests,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isUpcoming => status == 'confirmed' || status == 'rescheduled';
}
