import 'package:flutter_test/flutter_test.dart';
import 'package:qroutex/models/booking_model.dart';
import 'package:qroutex/models/event_model.dart';
import 'package:qroutex/utils/constants.dart';

void main() {
  group('BookingModel Tests', () {
    test('BookingModel parses valid JSON accurately', () {
      final json = {
        'id': 'QX-BK12345',
        'business_id': 42,
        'business_name': 'Paradise Biryani & Banquets',
        'business_category': 'food',
        'service_name': 'Rooftop VIP Cabana',
        'service_price': 1500.0,
        'date': '2026-11-25',
        'time_slot': '08:00 PM',
        'guests_count': 6,
        'status': 'confirmed',
        'special_requests': 'Candlelight dinner arrangement',
        'customer_name': 'Vikram Rao',
        'customer_phone': '+91 98765 00000',
        'created_at': '2026-11-20T10:00:00Z',
      };

      final booking = BookingModel.fromJson(json);

      expect(booking.id, equals('QX-BK12345'));
      expect(booking.businessId, equals(42));
      expect(booking.businessName, equals('Paradise Biryani & Banquets'));
      expect(booking.serviceName, equals('Rooftop VIP Cabana'));
      expect(booking.servicePrice, equals(1500.0));
      expect(booking.date, equals('2026-11-25'));
      expect(booking.timeSlot, equals('08:00 PM'));
      expect(booking.guestsCount, equals(6));
      expect(booking.status, equals('confirmed'));
      expect(booking.customerName, equals('Vikram Rao'));
      expect(booking.customerPhone, equals('+91 98765 00000'));
    });

    test('BookingModel serializes toJson consistently', () {
      final booking = BookingModel(
        id: 'QX-BK99999',
        businessId: 10,
        businessName: 'Royal Decorators',
        businessCategory: 'event_services',
        serviceName: 'Mandap Floral Setup',
        servicePrice: 35000.0,
        date: '2026-12-05',
        time_slot: '11:00 AM',
        guestsCount: 200,
        status: 'pending',
        special_requests: 'Marigold & Jasmine theme',
        customerName: 'Priya Verma',
        customerPhone: '+91 91111 22222',
        createdAt: DateTime.parse('2026-11-20T08:30:00Z'),
      );

      final json = booking.toJson();
      expect(json['id'], equals('QX-BK99999'));
      expect(json['business_id'], equals(10));
      expect(json['business_name'], equals('Royal Decorators'));
      expect(json['status'], equals('pending'));
      expect(json['guests_count'], equals(200));
    });
  });

  group('EventModel Tests', () {
    test('EventModel correctly constructs from minimal JSON with fallback GPS link', () {
      final json = {
        'id': 1,
        'title': 'Grand Graduation Gala 2026',
        'slug': 'grand-graduation-gala-2026',
        'event_type': 'celebration',
        'host_names': 'Dean & Faculty',
        'description': 'Annual graduation party with live music and photo booths.',
        'event_date': '2026-12-15',
        'venue_name': 'Novotel Convention Hall',
        'venue_address': 'HITEC City, Hyderabad, Telangana',
        'is_published': true,
      };

      final event = EventModel.fromJson(json);

      expect(event.id, equals(1));
      expect(event.title, equals('Grand Graduation Gala 2026'));
      expect(event.isPublished, isTrue);
      expect(event.venueName, equals('Novotel Convention Hall'));
      // Fallback Google Maps directions
      expect(event.effectiveDirectionsUrl, contains('google.com/maps/dir'));
      expect(event.effectiveDirectionsUrl, contains('Novotel%20Convention%20Hall'));
    });
  });

  group('AppConstants & Configuration Tests', () {
    test('App name and website URLs are configured properly', () {
      expect(AppConstants.appName, equals('QRouteX'));
      expect(AppConstants.siteUrl, contains('qroutex.com'));
      expect(AppConstants.primaryColor, isNotNull);
      expect(AppConstants.accentColor, isNotNull);
    });
  });
}
