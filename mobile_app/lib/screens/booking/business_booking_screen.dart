import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/business_model.dart';
import '../../models/booking_model.dart';
import '../../services/api_service.dart';

class BusinessBookingScreen extends StatefulWidget {
  final BusinessModel business;
  final BusinessServiceModel? selectedService;

  const BusinessBookingScreen({
    Key? key,
    required this.business,
    this.selectedService,
  }) : super(key: key);

  @override
  State<BusinessBookingScreen> createState() => _BusinessBookingScreenState();
}

class _BusinessBookingScreenState extends State<BusinessBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  late BusinessServiceModel? _chosenService;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '07:00 PM - 08:30 PM';
  int _guestsCount = 2;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialRequestsController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _timeSlots = [
    '11:00 AM - 12:30 PM',
    '01:00 PM - 02:30 PM',
    '04:00 PM - 05:30 PM',
    '06:00 PM - 07:30 PM',
    '07:00 PM - 08:30 PM',
    '08:30 PM - 10:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _chosenService = widget.selectedService ??
        (widget.business.services.isNotEmpty ? widget.business.services.first : null);
    _nameController.text = 'QRouteX Member';
    _phoneController.text = widget.business.phone.isNotEmpty ? widget.business.phone : '+91 98765 43210';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppConstants.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppConstants.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _confirmBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final bookingId = 'QX-BK${DateTime.now().millisecondsSinceEpoch % 100000}';
    final dateFormatted = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    double? priceValue;
    if (_chosenService?.priceDisplay != null) {
      final numStr = _chosenService!.priceDisplay!.replaceAll(RegExp(r'[^\d.]'), '');
      priceValue = double.tryParse(numStr);
    }

    final newBooking = BookingModel(
      id: bookingId,
      businessId: widget.business.id,
      businessName: widget.business.name,
      businessCategory: widget.business.categoryTitle,
      serviceName: _chosenService?.name ?? 'Standard Reservation',
      servicePrice: priceValue != null ? priceValue * _guestsCount : null,
      date: dateFormatted,
      timeSlot: _selectedTimeSlot,
      guestsCount: _guestsCount,
      status: 'confirmed',
      specialRequests: _specialRequestsController.text.trim().isEmpty ? null : _specialRequestsController.text.trim(),
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      createdAt: DateTime.now(),
    );

    await ApiService.createBooking(newBooking);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 48),
              ),
              const SizedBox(height: 16),
              const Text('Booking Confirmed!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 6),
              Text(
                'Your reservation with ${widget.business.name} is locked in.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppConstants.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Booking ID', bookingId, isBold: true),
                    const Divider(height: 12),
                    _buildSummaryRow('Date', dateFormatted),
                    _buildSummaryRow('Time Slot', _selectedTimeSlot),
                    _buildSummaryRow('Guests / Units', '$_guestsCount Guests'),
                    if (_chosenService != null) _buildSummaryRow('Selected Package', _chosenService!.name),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Return to previous screen
                },
                child: const Text('View in My Bookings', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppConstants.textMuted)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: AppConstants.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.business;
    final dateStr = "${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Book ${b.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Partner Highlight Card ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppConstants.primaryColor.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(b.categoryEmoji, style: const TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  b.name,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (b.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, color: AppConstants.accentColor, size: 16),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(b.categoryTitle, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            '📍 ${b.city.isNotEmpty ? b.city : "Bengaluru"} • Direct Booking Guarantee',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Step 1: Select Service / Package ──
              if (b.services.isNotEmpty) ...[
                const Text('1. Select Service or Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppConstants.textDark)),
                const SizedBox(height: 10),
                ...b.services.map((service) {
                  final isSelected = _chosenService?.id == service.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? AppConstants.primaryColor : Colors.grey.shade200, width: isSelected ? 2 : 1),
                    ),
                    child: ListTile(
                      onTap: () => setState(() => _chosenService = service),
                      leading: Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? AppConstants.primaryColor : Colors.grey,
                      ),
                      title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: service.description.isNotEmpty ? Text(service.description, style: const TextStyle(fontSize: 12)) : null,
                      trailing: service.priceDisplay != null
                          ? Text(
                              service.priceDisplay!,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 13),
                            )
                          : null,
                    ),
                  );
                }),
                const SizedBox(height: 18),
              ],

              // ── Step 2: Date & Time Slot Selection ──
              const Text('2. Choose Reservation Date & Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppConstants.textDark)),
              const SizedBox(height: 10),
              // Date picker button
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppConstants.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Selected Date', style: TextStyle(fontSize: 11, color: AppConstants.textMuted)),
                            Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppConstants.textDark)),
                          ],
                        ),
                      ),
                      const Text('Change', style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Time slots chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeSlots.map((slot) {
                  final isSelected = _selectedTimeSlot == slot;
                  return ChoiceChip(
                    label: Text(slot),
                    selected: isSelected,
                    selectedColor: AppConstants.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppConstants.textDark,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _selectedTimeSlot = slot),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // ── Step 3: Guests & Contact Information ──
              const Text('3. Guests & Contact Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppConstants.textDark)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Number of Guests / Seats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppConstants.primaryColor),
                              onPressed: _guestsCount > 1 ? () => setState(() => _guestsCount--) : null,
                            ),
                            Text('$_guestsCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppConstants.primaryColor),
                              onPressed: _guestsCount < 50 ? () => setState(() => _guestsCount++) : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Primary Contact Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter phone' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _specialRequestsController,
                      decoration: const InputDecoration(
                        labelText: 'Special Notes / Dietary / Seating (Optional)',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Booking Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                ),
                icon: _isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isSubmitting ? 'Confirming Reservation...' : 'Confirm Booking Now',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: _isSubmitting ? null : _confirmBooking,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
