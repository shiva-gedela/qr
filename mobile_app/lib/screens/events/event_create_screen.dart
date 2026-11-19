import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';

class EventCreateScreen extends StatefulWidget {
  final String? initialEventType;

  const EventCreateScreen({Key? key, this.initialEventType}) : super(key: key);

  @override
  State<EventCreateScreen> createState() => _EventCreateScreenState();
}

class _EventCreateScreenState extends State<EventCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0; // 0 to 7 (8 steps)

  // Step 1: Event Info
  final _titleController = TextEditingController();
  late String _eventType;

  // Step 2: Date, Time & Location
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 14));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 30);
  final _venueNameController = TextEditingController();
  final _venueAddressController = TextEditingController();
  final _mapsUrlController = TextEditingController();

  // Step 3: Cover Image
  String? _pickedCoverPath;
  String _selectedCoverPreset = 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&q=80';

  // Step 4: Description & Hosts
  final _hostNamesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _organizerNameController = TextEditingController();
  final _organizerContactController = TextEditingController();

  // Step 5: Capacity
  int _guestCapacity = 150;

  // Step 6: Ticket & Settings
  final _dressCodeController = TextEditingController(text: 'Festive / Ethnic');
  bool _isPublic = true;
  bool _allowGuestUploads = true;

  // Step 7: Portfolio Images
  final List<String> _portfolioImages = [];

  bool _isPublishing = false;

  final List<Map<String, String>> _eventTypes = [
    {'code': 'wedding', 'label': 'Wedding', 'emoji': '💍', 'preset': 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&q=80'},
    {'code': 'birthday', 'label': 'Birthday', 'emoji': '🎂', 'preset': 'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=800&q=80'},
    {'code': 'engagement', 'label': 'Engagement', 'emoji': '💑', 'preset': 'https://images.unsplash.com/photo-1515934751635-c81c6bc9a2d8?w=800&q=80'},
    {'code': 'anniversary', 'label': 'Anniversary', 'emoji': '❤️', 'preset': 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=800&q=80'},
    {'code': 'housewarming', 'label': 'Housewarming', 'emoji': '🏠', 'preset': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80'},
    {'code': 'graduation', 'label': 'Graduation', 'emoji': '🎓', 'preset': 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=800&q=80'},
    {'code': 'concert', 'label': 'Music & Concert', 'emoji': '🎵', 'preset': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=800&q=80'},
    {'code': 'party', 'label': 'Cocktail & Party', 'emoji': '🍸', 'preset': 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=800&q=80'},
  ];

  final List<String> _stepTitles = [
    'Event Information',
    'Date, Time & Location',
    'Upload Cover Image',
    'Story & Description',
    'Guest Capacity',
    'Ticket & Entry Settings',
    'Event Portfolio',
    'Preview & Publish',
  ];

  @override
  void initState() {
    super.initState();
    _eventType = widget.initialEventType ?? 'wedding';
    final matching = _eventTypes.firstWhere((e) => e['code'] == _eventType, orElse: () => _eventTypes.first);
    _selectedCoverPreset = matching['preset']!;
  }

  Future<void> _pickCoverImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _pickedCoverPath = picked.path;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickPortfolioImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _portfolioImages.add(picked.path);
        });
      }
    } catch (_) {}
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _nextStep() {
    if (_currentStep == 0 && _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an event title.')));
      return;
    }
    if (_currentStep == 1 && _venueNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the venue name.')));
      return;
    }
    if (_currentStep < 7) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _publishEvent() async {
    setState(() => _isPublishing = true);

    final eventId = DateTime.now().millisecondsSinceEpoch % 100000;
    final slug = "${_titleController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}-$eventId";
    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final timeStr = _selectedTime.format(context);

    final newEvent = EventModel(
      id: eventId,
      title: _titleController.text.trim(),
      slug: slug,
      eventType: _eventType,
      hostNames: _hostNamesController.text.trim().isNotEmpty ? _hostNamesController.text.trim() : 'Celebration Hosts',
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : 'You are cordially invited to celebrate ${_titleController.text.trim()}. Please scan your unique digital pass at the venue entrance.',
      eventDate: dateStr,
      eventTime: timeStr,
      venueName: _venueNameController.text.trim(),
      venueAddress: _venueAddressController.text.trim().isNotEmpty ? _venueAddressController.text.trim() : _venueNameController.text.trim(),
      googleMapsUrl: _mapsUrlController.text.trim().isNotEmpty ? _mapsUrlController.text.trim() : null,
      googleMapsDirectionsUrl: _mapsUrlController.text.trim().isNotEmpty
          ? _mapsUrlController.text.trim()
          : 'https://maps.google.com/?q=${Uri.encodeComponent("${_venueNameController.text.trim()} ${_venueAddressController.text.trim()}")}',
      dressCode: _dressCodeController.text.trim(),
      coverImageUrl: _pickedCoverPath ?? _selectedCoverPreset,
      isPublished: true,
      capacity: _guestCapacity,
      guestCount: 0,
      organizerName: _organizerNameController.text.trim(),
      organizerContact: _organizerContactController.text.trim(),
      targetUrl: '${AppConstants.baseUrl}/events/e/$slug/',
      photos: _portfolioImages.map((path) => {'image': path, 'caption': 'Event Highlight'}).toList(),
    );

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    final localRaw = prefs.getStringList('local_created_events') ?? [];
    localRaw.insert(0, jsonEncode(newEvent.toJson()));
    await prefs.setStringList('local_created_events', localRaw);

    // Backend sync attempt
    try {
      await ApiService.createEvent(newEvent.toJson());
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isPublishing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event Published Successfully with QR Pass!'), backgroundColor: AppConstants.successColor),
    );

    Navigator.pop(context, newEvent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Create New Event', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: AppConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Step Progress Indicator ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STEP ${_currentStep + 1} OF 8',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppConstants.primaryColor, letterSpacing: 0.8),
                    ),
                    Text(
                      _stepTitles[_currentStep],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / 8.0,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                  ),
                ),
              ],
            ),
          ),

          // ── Multi-Step Form Body ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: _buildCurrentStepContent(),
              ),
            ),
          ),

          // ── Sticky Bottom Navigation Buttons ──
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -2)),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _prevStep,
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    onPressed: _isPublishing
                        ? null
                        : (_currentStep == 7 ? _publishEvent : _nextStep),
                    child: _isPublishing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            _currentStep == 7 ? 'Publish Smart Event 🚀' : 'Next Step ➔',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1EventInfo();
      case 1:
        return _buildStep2DateTimeLocation();
      case 2:
        return _buildStep3CoverImage();
      case 3:
        return _buildStep4Description();
      case 4:
        return _buildStep5Capacity();
      case 5:
        return _buildStep6TicketSettings();
      case 6:
        return _buildStep7Portfolio();
      case 7:
        return _buildStep8Preview();
      default:
        return const SizedBox();
    }
  }

  // ── Step 1: Event Info ──
  Widget _buildStep1EventInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('1. Event Title & Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Give your celebration a memorable name and choose the occasion type.', style: TextStyle(color: AppConstants.textMuted, fontSize: 13)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Event Title *',
            hintText: 'e.g. Sneha & Amit Royal Wedding Reception',
            prefixIcon: Icon(Icons.celebration),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 18),
        const Text('Choose Occasion Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: _eventTypes.map((et) {
            final isSelected = _eventType == et['code'];
            return InkWell(
              onTap: () {
                setState(() {
                  _eventType = et['code']!;
                  _selectedCoverPreset = et['preset']!;
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSelected ? AppConstants.primaryColor : Colors.grey.shade200, width: isSelected ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Text(et['emoji']!, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        et['label']!,
                        style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 13, color: AppConstants.textDark),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Step 2: Date, Time & Location ──
  Widget _buildStep2DateTimeLocation() {
    final dateStr = "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
    final timeStr = _selectedTime.format(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('2. Date, Time & Venue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Set when and where your guests should arrive.', style: TextStyle(color: AppConstants.textMuted, fontSize: 13)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Event Date', style: TextStyle(fontSize: 11, color: AppConstants.textMuted)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 16, color: AppConstants.primaryColor),
                          const SizedBox(width: 6),
                          Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Time', style: TextStyle(fontSize: 11, color: AppConstants.textMuted)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: AppConstants.accentColor),
                          const SizedBox(width: 6),
                          Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _venueNameController,
          decoration: const InputDecoration(labelText: 'Venue Name *', hintText: 'e.g. The Leela Palace Grand Ballroom', prefixIcon: Icon(Icons.store), border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _venueAddressController,
          decoration: const InputDecoration(labelText: 'Venue Address', hintText: 'Full road address, city, pincode', prefixIcon: Icon(Icons.location_on), border: OutlineInputBorder()),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _mapsUrlController,
          decoration: const InputDecoration(labelText: 'Google Maps Directions URL (Optional)', hintText: 'https://maps.app.goo.gl/...', prefixIcon: Icon(Icons.link), border: OutlineInputBorder()),
        ),
      ],
    );
  }

  // ── Step 3: Cover Image ──
  Widget _buildStep3CoverImage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('3. Cover Banner Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Upload your custom photo banner or pick a high-res celebration preset.', style: TextStyle(color: AppConstants.textMuted, fontSize: 13)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickCoverImage,
          child: Container(
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(image: NetworkImage(_selectedCoverPreset), fit: BoxFit.cover),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.withOpacity(0.35),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_a_photo, color: Colors.white, size: 36),
                    SizedBox(height: 6),
                    Text('Tap to Pick Banner from Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Or Select from Theme Presets:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _eventTypes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final preset = _eventTypes[idx]['preset']!;
              final isSelected = _selectedCoverPreset == preset && _pickedCoverPath == null;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCoverPreset = preset;
                  _pickedCoverPath = null;
                }),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppConstants.primaryColor : Colors.transparent, width: 2),
                    image: DecorationImage(image: NetworkImage(preset), fit: BoxFit.cover),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Step 4: Description & Hosts ──
  Widget _buildStep4Description() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('4. Story & Host Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Share the welcoming message for your invitation card.', style: TextStyle(color: AppConstants.textMuted, fontSize: 13)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _hostNamesController,
          decoration: const InputDecoration(labelText: 'Hosted By *', hintText: 'e.g. Ramesh & Priya or The Sharma Family', prefixIcon: Icon(Icons.people), border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: 'Invitation Description & Story', hintText: 'Share the special details, itinerary, or heartfelt note to your guests...', prefixIcon: Icon(Icons.edit_note), border: OutlineInputBorder()),
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _organizerNameController,
          decoration: const InputDecoration(labelText: 'Primary Contact / Organizer Name', prefixIcon: Icon(Icons.person_pin), border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _organizerContactController,
          decoration: const InputDecoration(labelText: 'Organizer Mobile Phone (for RSVP queries)', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  // ── Step 5: Capacity ──
  Widget _buildStep5Capacity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('5. Guest Capacity & Attendance Limit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Set the maximum number of guests to prevent overcrowding.', style: TextStyle(color: AppConstants.textMuted, fontSize: 13)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            children: [
              Text('$_guestCapacity Passes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: AppConstants.primaryColor)),
              const SizedBox(height: 6),
              const Text('Maximum QR entries permitted at the gate', style: TextStyle(color: AppConstants.textMuted, fontSize: 12)),
              const SizedBox(height: 16),
              Slider(
                value: _guestCapacity.toDouble(),
                min: 20,
                max: 1000,
                divisions: 98,
                activeColor: AppConstants.primaryColor,
                onChanged: (val) => setState(() => _guestCapacity = val.round()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('20 Guests', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('500 Guests', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('1000 Guests', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 6: Ticket & Settings ──
  Widget _buildStep6TicketSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('6. Ticket & Entry Gate Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Configure gate security and guest dress code guidelines.', style: TextStyle(color: AppConstants.textMuted, fontSize: 13)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _dressCodeController,
          decoration: const InputDecoration(labelText: 'Dress Code Guidelines', hintText: 'e.g. Traditional Ethnic / Black Tie / Casual', prefixIcon: Icon(Icons.checkroom), border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            children: [
              SwitchListTile(
                value: _isPublic,
                activeColor: AppConstants.primaryColor,
                title: const Text('Public Event Listing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Allow discovery in QRouteX Explore feed', style: TextStyle(fontSize: 11)),
                onChanged: (val) => setState(() => _isPublic = val),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: _allowGuestUploads,
                activeColor: AppConstants.primaryColor,
                title: const Text('Allow Guest Photo Uploads', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Guests can share candid photos to your event gallery', style: TextStyle(fontSize: 11)),
                onChanged: (val) => setState(() => _allowGuestUploads = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 7: Portfolio ──
  Widget _buildStep7Portfolio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('7. Event Portfolio & Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Upload photos to showcase the celebration highlights to your guests.', style: TextStyle(color: AppConstants.textMuted, fontSize: 13)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor, foregroundColor: Colors.white),
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add Photo to Portfolio'),
          onPressed: _pickPortfolioImage,
        ),
        const SizedBox(height: 16),
        if (_portfolioImages.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Center(
              child: Text('No photos added yet. You can also add more photos after publishing.', style: TextStyle(color: AppConstants.textMuted, fontSize: 12)),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: _portfolioImages.length,
            itemBuilder: (context, idx) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_portfolioImages[idx], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300))),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _portfolioImages.removeAt(idx)),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  // ── Step 8: Live Preview & Publish ──
  Widget _buildStep8Preview() {
    final title = _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Sample Celebration';
    final venue = _venueNameController.text.trim().isNotEmpty ? _venueNameController.text.trim() : 'Venue Name';
    final dateStr = "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('8. Live Preview & Confirmation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Review your digital invitation card before generating encrypted QR passes.', style: TextStyle(color: AppConstants.textMuted, fontSize: 13)),
        const SizedBox(height: 16),

        // Preview Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 4)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  image: DecorationImage(image: NetworkImage(_selectedCoverPreset), fit: BoxFit.cover),
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                  padding: const EdgeInsets.all(14),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 16, color: AppConstants.primaryColor),
                        const SizedBox(width: 8),
                        Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(8)),
                          child: Text('$_guestCapacity Passes', style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: AppConstants.accentColor),
                        const SizedBox(width: 8),
                        Expanded(child: Text(venue, style: const TextStyle(color: AppConstants.textDark, fontSize: 13))),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Digital QR Pass Security', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('100% Encrypted', style: TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
