import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import 'invitation_card_view_screen.dart';

class EventCreateScreen extends StatefulWidget {
  final String? initialEventType;
  const EventCreateScreen({Key? key, this.initialEventType}) : super(key: key);

  @override
  State<EventCreateScreen> createState() => _EventCreateScreenState();
}

class _EventCreateScreenState extends State<EventCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _hostNamesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueNameController = TextEditingController();
  final _venueAddressController = TextEditingController();
  final _mapsUrlController = TextEditingController();
  final _organizerNameController = TextEditingController();
  final _organizerContactController = TextEditingController();
  final _capacityController = TextEditingController(text: '150');
  final _instagramController = TextEditingController();
  final _dressCodeController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 14));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  late String _eventType;
  String? _selectedCoverPreset;
  String? _pickedCoverPath;
  bool _isLoading = false;
  int _currentStep = 0; // 0: Details, 1: Venue & Time, 2: Capacity & Preview

  final List<Map<String, String>> _eventTypes = [
    {'code': 'wedding', 'label': 'Wedding', 'emoji': '💍', 'bg': 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&q=80'},
    {'code': 'birthday', 'label': 'Birthday', 'emoji': '🎂', 'bg': 'https://images.unsplash.com/photo-1513151233558-d860c5398176?w=800&q=80'},
    {'code': 'engagement', 'label': 'Engagement', 'emoji': '💑', 'bg': 'https://images.unsplash.com/photo-1515934751635-c81c6bc9a2d8?w=800&q=80'},
    {'code': 'anniversary', 'label': 'Anniversary', 'emoji': '❤️', 'bg': 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=800&q=80'},
    {'code': 'housewarming', 'label': 'Housewarming', 'emoji': '🏠', 'bg': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80'},
    {'code': 'graduation', 'label': 'Graduation', 'emoji': '🎓', 'bg': 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=800&q=80'},
  ];

  @override
  void initState() {
    super.initState();
    _eventType = widget.initialEventType ?? 'wedding';
    final matching = _eventTypes.firstWhere((e) => e['code'] == _eventType, orElse: () => _eventTypes.first);
    _selectedCoverPreset = matching['bg'];
  }

  void _onEventTypeChanged(String code) {
    setState(() {
      _eventType = code;
      final matching = _eventTypes.firstWhere((e) => e['code'] == code, orElse: () => _eventTypes.first);
      _selectedCoverPreset = matching['bg'];
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _pickedCoverPath = picked.path;
          _selectedCoverPreset = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _currentStep = 0);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      final timeStr = "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00";

      final created = await ApiService.createEvent({
        'title': _titleController.text.trim(),
        'host_names': _hostNamesController.text.trim(),
        'description': _descriptionController.text.trim(),
        'event_type': _eventType,
        'event_date': dateStr,
        'event_time': timeStr,
        'venue_name': _venueNameController.text.trim(),
        'venue_address': _venueAddressController.text.trim(),
        'maps_url': _mapsUrlController.text.trim().isNotEmpty
            ? _mapsUrlController.text.trim()
            : 'https://maps.google.com/?q=${Uri.encodeComponent("${_venueNameController.text.trim()} ${_venueAddressController.text.trim()}")}',
        'organizer_name': _organizerNameController.text.trim(),
        'organizer_contact': _organizerContactController.text.trim(),
        'capacity': int.tryParse(_capacityController.text.trim()) ?? 150,
        'instagram_url': _instagramController.text.trim(),
        'dress_code': _dressCodeController.text.trim(),
        'cover_image_url': _selectedCoverPreset,
        'is_published': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Smart Event QR & Invitation created successfully!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => InvitationCardViewScreen(event: created)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppConstants.dangerColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final timeStr = "${_selectedTime.format(context)}";

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Create New Event QR', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.primaryDark,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Step Progress Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  _buildStepBubble(0, '1. Details'),
                  _buildStepConnector(0),
                  _buildStepBubble(1, '2. Venue & GPS'),
                  _buildStepConnector(1),
                  _buildStepBubble(2, '3. Capacity & Card'),
                ],
              ),
            ),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_currentStep == 0) _buildStepDetails(),
                    if (_currentStep == 1) _buildStepVenueAndDate(dateStr, timeStr),
                    if (_currentStep == 2) _buildStepCapacityAndLivePreview(dateStr, timeStr),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => setState(() => _currentStep--),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_currentStep < 2) {
                                setState(() => _currentStep++);
                              } else {
                                _handleSubmit();
                              }
                            },
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _currentStep == 2 ? 'Generate Event QR & Card' : 'Continue to Next Step →',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBubble(int stepIndex, String title) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    return GestureDetector(
      onTap: () => setState(() => _currentStep = stepIndex),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isDone
                ? AppConstants.successColor
                : (isActive ? AppConstants.primaryColor : Colors.grey.shade300),
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppConstants.primaryColor : AppConstants.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int stepIndex) {
    final isDone = _currentStep > stepIndex;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: isDone ? AppConstants.successColor : Colors.grey.shade300,
      ),
    );
  }

  // ── Step 0: Basic Details & Occasion Selector ──
  Widget _buildStepDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Event Occasion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: _eventTypes.length,
          itemBuilder: (context, idx) {
            final type = _eventTypes[idx];
            final isSelected = _eventType == type['code'];

            return GestureDetector(
              onTap: () => _onEventTypeChanged(type['code']!),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppConstants.purpleSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppConstants.primaryColor : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(color: AppConstants.primaryColor.withOpacity(0.18), blurRadius: 8),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(type['emoji']!, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 4),
                    Text(
                      type['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppConstants.primaryColor : AppConstants.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        const Text('Event Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),

        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Event Title *',
            hintText: 'e.g. Priya & Rahul Grand Wedding',
            prefixIcon: const Icon(Icons.celebration, color: AppConstants.primaryColor),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _hostNamesController,
          decoration: InputDecoration(
            labelText: 'Host Names *',
            hintText: 'e.g. Sharma & Gupta Families',
            prefixIcon: const Icon(Icons.people, color: AppConstants.primaryColor),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => v == null || v.trim().isEmpty ? 'Host names are required' : null,
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Invitation Message / Description',
            hintText: 'Write a warm invitation message for your guests...',
            alignLabelWithHint: true,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  // ── Step 1: Venue, GPS Location, Date & Time ──
  Widget _buildStepVenueAndDate(String dateStr, String timeStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppConstants.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: AppConstants.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        const Text('Venue & GPS Navigation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),

        TextFormField(
          controller: _venueNameController,
          decoration: InputDecoration(
            labelText: 'Venue Name *',
            hintText: 'e.g. The Leela Palace Ballroom',
            prefixIcon: const Icon(Icons.location_city, color: AppConstants.primaryColor),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => v == null || v.trim().isEmpty ? 'Venue name is required' : null,
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _venueAddressController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Full Address *',
            hintText: 'e.g. Old Airport Road, Kodihalli, Bengaluru, Karnataka 560008',
            prefixIcon: const Icon(Icons.place, color: AppConstants.primaryColor),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => v == null || v.trim().isEmpty ? 'Venue address is required' : null,
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _mapsUrlController,
          decoration: InputDecoration(
            labelText: 'Google Maps Link (Optional)',
            hintText: 'Paste Google Maps share link or leave empty to auto-generate',
            prefixIcon: const Icon(Icons.directions, color: AppConstants.accentColor),
            helperText: 'Guests can 1-tap navigate turn-by-turn from their smartphones',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  // ── Step 2: Capacity, Organizer & Live Interactive Preview ──
  Widget _buildStepCapacityAndLivePreview(String dateStr, String timeStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Guest Capacity & Organizer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Guest Capacity',
                  hintText: 'e.g. 200',
                  prefixIcon: const Icon(Icons.people_outline, color: AppConstants.primaryColor),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _dressCodeController,
                decoration: InputDecoration(
                  labelText: 'Dress Code',
                  hintText: 'e.g. Traditional / Royal',
                  prefixIcon: const Icon(Icons.checkroom, color: AppConstants.primaryColor),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _organizerNameController,
                decoration: InputDecoration(
                  labelText: 'Organizer Name',
                  hintText: 'Contact Person',
                  prefixIcon: const Icon(Icons.person_pin, color: AppConstants.primaryColor),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _organizerContactController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Organizer Contact',
                  hintText: '+91 98765 43210',
                  prefixIcon: const Icon(Icons.phone, color: AppConstants.primaryColor),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Cover Photo Section ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Event Cover Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt, size: 16),
              label: const Text('Upload Photo'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Preset Banners Row
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _eventTypes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, idx) {
              final type = _eventTypes[idx];
              final isSelected = _selectedCoverPreset == type['bg'] && _pickedCoverPath == null;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCoverPreset = type['bg'];
                    _pickedCoverPath = null;
                  });
                },
                child: Container(
                  width: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppConstants.primaryColor : Colors.transparent,
                      width: 2.5,
                    ),
                    image: DecorationImage(
                      image: NetworkImage(type['bg']!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    color: Colors.black45,
                    child: Text(type['emoji']!, style: const TextStyle(fontSize: 18)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // ── Live Interactive Invitation Card Preview ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppConstants.purpleSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.remove_red_eye, color: AppConstants.primaryColor, size: 16),
              SizedBox(width: 6),
              Text(
                'LIVE INVITATION CARD PREVIEW',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppConstants.primaryColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B0764), Color(0xFF1E1B4B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppConstants.accentColor, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 16),
            ],
          ),
          child: Column(
            children: [
              Text(
                '${_eventTypes.firstWhere((e) => e['code'] == _eventType)['emoji']} ${_eventType.toUpperCase()} INVITATION',
                style: const TextStyle(color: AppConstants.accentColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              Text(
                _titleController.text.trim().isEmpty ? 'Your Event Title' : _titleController.text.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                _hostNamesController.text.trim().isEmpty ? 'Hosted by Host Names' : 'Hosted by ${_hostNamesController.text.trim()}',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, color: AppConstants.accentColor, size: 14),
                  const SizedBox(width: 4),
                  Text('$dateStr • $timeStr', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: AppConstants.accentColor, size: 14),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _venueNameController.text.trim().isEmpty ? 'Celebration Venue' : _venueNameController.text.trim(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '👥 Guest Capacity: ${_capacityController.text.trim()} Passes',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
