import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../models/booking_model.dart';
import '../../services/api_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'upcoming', 'completed', 'cancelled'

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getUserBookings();
    if (!mounted) return;
    setState(() {
      _bookings = list;
      _isLoading = false;
    });
  }

  void _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _cancelBookingPrompt(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cancel Booking?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to cancel your booking with ${booking.businessName}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep Booking')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerColor),
              onPressed: () async {
                Navigator.pop(context);
                await ApiService.cancelBooking(booking.id);
                _loadBookings();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking has been cancelled')),
                );
              },
              child: const Text('Cancel Reservation', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _bookings.where((b) {
      if (_selectedFilter == 'upcoming') return b.isUpcoming;
      if (_selectedFilter == 'completed') return b.status == 'completed';
      if (_selectedFilter == 'cancelled') return b.status == 'cancelled';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Bookings & Reservations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: AppConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBookings),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.white,
            child: Row(
              children: [
                _buildFilterChip('all', 'All Bookings'),
                const SizedBox(width: 8),
                _buildFilterChip('upcoming', 'Upcoming'),
                const SizedBox(width: 8),
                _buildFilterChip('completed', 'Completed'),
                const SizedBox(width: 8),
                _buildFilterChip('cancelled', 'Cancelled'),
              ],
            ),
          ),

          // Bookings List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEEF2FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.calendar_today_outlined, size: 36, color: AppConstants.primaryColor),
                              ),
                              const SizedBox(height: 16),
                              const Text('No bookings found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                              const SizedBox(height: 6),
                              const Text(
                                'Explore top restaurants, salons, and event vendors to make your first reservation.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppConstants.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBookings,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, idx) {
                            final b = filtered[idx];
                            return _buildBookingCard(b);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String code, String label) {
    final isSelected = _selectedFilter == code;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppConstants.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppConstants.textDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _selectedFilter = code),
    );
  }

  Widget _buildBookingCard(BookingModel b) {
    Color statusBg = const Color(0xFFD1FAE5);
    Color statusColor = const Color(0xFF10B981);
    String statusLabel = 'CONFIRMED';

    if (b.status == 'cancelled') {
      statusBg = const Color(0xFFFEE2E2);
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'CANCELLED';
    } else if (b.status == 'completed') {
      statusBg = const Color(0xFFE2E8F0);
      statusColor = const Color(0xFF64748B);
      statusLabel = 'COMPLETED';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ID and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                b.id,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppConstants.primaryColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Business Name & Category
          Text(
            b.businessName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.textDark),
          ),
          Text(
            '${b.businessCategory} • ${b.serviceName ?? "General Reservation"}',
            style: const TextStyle(color: AppConstants.textMuted, fontSize: 12),
          ),
          const Divider(height: 20),

          // Details Row
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 16, color: AppConstants.primaryColor),
                    const SizedBox(width: 6),
                    Text(b.date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: AppConstants.accentColor),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(b.timeSlot, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('${b.guestsCount} Guests', style: const TextStyle(fontSize: 12, color: AppConstants.textMuted)),
                ],
              ),
              if (b.servicePrice != null)
                Text(
                  '₹${b.servicePrice!.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF10B981)),
                ),
            ],
          ),

          if (b.specialRequests != null && b.specialRequests!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
              child: Text(
                'Note: ${b.specialRequests}',
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppConstants.textMuted),
              ),
            ),
          ],

          if (b.isUpcoming) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (b.customerPhone.isNotEmpty)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.call, size: 14),
                    label: const Text('Call', style: TextStyle(fontSize: 11)),
                    onPressed: () => _openUrl('tel:${b.customerPhone}'),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppConstants.dangerColor),
                  onPressed: () => _cancelBookingPrompt(b),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
