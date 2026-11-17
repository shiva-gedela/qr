import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/api_service.dart';

class EventCreateScreen extends StatefulWidget {
  const EventCreateScreen({Key? key}) : super(key: key);

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
  final _instagramController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _hashtagController = TextEditingController();
  final _dressCodeController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 14));
  String _eventType = 'wedding';
  bool _isLoading = false;

  final List<Map<String, String>> _eventTypes = [
    {'code': 'wedding', 'label': '💍 Wedding'},
    {'code': 'birthday', 'label': '🎂 Birthday'},
    {'code': 'engagement', 'label': '💑 Engagement'},
    {'code': 'anniversary', 'label': '❤️ Anniversary'},
    {'code': 'housewarming', 'label': '🏠 Housewarming'},
    {'code': 'graduation', 'label': '🎓 Graduation'},
    {'code': 'other', 'label': '🎉 Other Celebration'},
  ];

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      await ApiService.createEvent({
        'title': _titleController.text.trim(),
        'host_names': _hostNamesController.text.trim(),
        'description': _descriptionController.text.trim(),
        'event_type': _eventType,
        'event_date': dateStr,
        'venue_name': _venueNameController.text.trim(),
        'venue_address': _venueAddressController.text.trim(),
        'maps_url': _mapsUrlController.text.trim(),
        'instagram_url': _instagramController.text.trim(),
        'youtube_url': _youtubeController.text.trim(),
        'event_hashtag': _hashtagController.text.trim(),
        'dress_code': _dressCodeController.text.trim(),
        'is_published': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!'), backgroundColor: AppConstants.successColor),
        );
        Navigator.pop(context, true);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event Title *', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _eventType,
                decoration: const InputDecoration(labelText: 'Event Type', border: OutlineInputBorder()),
                items: _eventTypes.map((t) => DropdownMenuItem(value: t['code'], child: Text(t['label']!))).toList(),
                onChanged: (val) => setState(() => _eventType = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hostNamesController,
                decoration: const InputDecoration(labelText: 'Host Names *', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Enter host names' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Event Date'),
                subtitle: Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
                trailing: const Icon(Icons.calendar_month, color: AppConstants.primaryColor),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _venueNameController,
                decoration: const InputDecoration(labelText: 'Venue Name *', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Enter venue' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _venueAddressController,
                decoration: const InputDecoration(labelText: 'Full Address *', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Enter address' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mapsUrlController,
                decoration: const InputDecoration(labelText: 'Google Maps GPS Navigation URL', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instagramController,
                decoration: const InputDecoration(labelText: 'Instagram Profile / Event Page', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _youtubeController,
                decoration: const InputDecoration(labelText: 'YouTube Live Stream (Virtual Guests)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hashtagController,
                      decoration: const InputDecoration(labelText: 'Event Hashtag (e.g. #PriyaWedsRam)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _dressCodeController,
                      decoration: const InputDecoration(labelText: 'Dress Code (e.g. Festive)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Generate Event & QR Code', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
