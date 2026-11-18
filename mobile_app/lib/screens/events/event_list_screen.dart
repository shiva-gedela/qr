import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import 'event_create_screen.dart';
import 'event_detail_screen.dart';
import 'invitation_card_view_screen.dart';
import 'event_portfolio_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({Key? key}) : super(key: key);

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  late Future<List<EventModel>> _eventsFuture;
  String _selectedFilter = 'all';

  final List<Map<String, String>> _filterOptions = [
    {'code': 'all', 'label': 'All Celebrations', 'emoji': '🌟'},
    {'code': 'wedding', 'label': 'Weddings', 'emoji': '💍'},
    {'code': 'birthday', 'label': 'Birthdays', 'emoji': '🎂'},
    {'code': 'engagement', 'label': 'Engagements', 'emoji': '💑'},
    {'code': 'anniversary', 'label': 'Anniversaries', 'emoji': '❤️'},
    {'code': 'housewarming', 'label': 'Housewarmings', 'emoji': '🏠'},
    {'code': 'graduation', 'label': 'Graduations', 'emoji': '🎓'},
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      _eventsFuture = ApiService.getEvents();
    });
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareViaWhatsApp(EventModel event) async {
    final message = event.shareMessage;
    final whatsappUrl = "whatsapp://send?text=${Uri.encodeComponent(message)}";
    final webUrl = "https://api.whatsapp.com/send?text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else if (await canLaunchUrl(Uri.parse(webUrl))) {
      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    } else {
      Clipboard.setData(ClipboardData(text: message));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation copied to clipboard!')),
        );
      }
    }
  }

  void _showManageModal(EventModel event) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppConstants.purpleSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(event.eventTypeIcon, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${event.eventDate} • ${event.venueName}', style: const TextStyle(fontSize: 12, color: AppConstants.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              ListTile(
                leading: const Icon(Icons.remove_red_eye, color: AppConstants.primaryColor),
                title: const Text('Digital Invitation Card & Themes'),
                subtitle: const Text('View premium card preview & unique QR', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => InvitationCardViewScreen(event: event)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF0284C7)),
                title: const Text('Event Portfolio & Moments Gallery'),
                subtitle: const Text('Upload & manage event photos', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => EventPortfolioScreen(event: event)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444)),
                title: const Text('Download Printable Vector A4 PDF Card'),
                subtitle: const Text('High-resolution print-ready vector file', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  final pdfUrl = event.downloadPdfUrl ?? (event.qrUuid != null ? '${AppConstants.baseUrl}/qr/download/pdf/${event.qrUuid}/' : '${AppConstants.baseUrl}/events/e/${event.slug}/');
                  _openUrl(pdfUrl);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Color(0xFF10B981)),
                title: const Text('Share via WhatsApp with GPS Route'),
                subtitle: const Text('Direct message with RSVP & Google Maps link', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  _shareViaWhatsApp(event);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQuickEdit(EventModel event) {
    final titleCtrl = TextEditingController(text: event.title);
    final venueCtrl = TextEditingController(text: event.venueName);
    final addressCtrl = TextEditingController(text: event.venueAddress);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Quick Edit Event', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Event Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: venueCtrl,
                  decoration: const InputDecoration(labelText: 'Venue Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Venue Address', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final localEventsRaw = prefs.getStringList('local_created_events') ?? [];
                final updatedList = <String>[];

                for (final item in localEventsRaw) {
                  try {
                    final data = jsonDecode(item);
                    if (data['id'] == event.id) {
                      data['title'] = titleCtrl.text.trim();
                      data['venue_name'] = venueCtrl.text.trim();
                      data['venue_address'] = addressCtrl.text.trim();
                      updatedList.add(jsonEncode(data));
                    } else {
                      updatedList.add(item);
                    }
                  } catch (_) {
                    updatedList.add(item);
                  }
                }
                await prefs.setStringList('local_created_events', updatedList);
                Navigator.pop(context);
                _loadEvents();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event details updated!'), backgroundColor: AppConstants.successColor),
                );
              },
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Events & Invitations', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadEvents,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppConstants.accentColor, size: 28),
            tooltip: 'Create Event',
            onPressed: () async {
              final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EventCreateScreen()));
              if (created != null) _loadEvents();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Scrollable Bar
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filterOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final opt = _filterOptions[idx];
                final isSelected = _selectedFilter == opt['code'];
                return ChoiceChip(
                  label: Text('${opt['emoji']} ${opt['label']}'),
                  selected: isSelected,
                  selectedColor: AppConstants.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppConstants.textDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _selectedFilter = opt['code']!),
                );
              },
            ),
          ),

          // Event Card List
          Expanded(
            child: RefreshIndicator(
              color: AppConstants.primaryColor,
              onRefresh: () async => _loadEvents(),
              child: FutureBuilder<List<EventModel>>(
                future: _eventsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allEvents = snapshot.data ?? [];
                  final filtered = _selectedFilter == 'all'
                      ? allEvents
                      : allEvents.where((e) => e.eventType.toLowerCase() == _selectedFilter).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.celebration_outlined, size: 64, color: AppConstants.textMuted),
                            const SizedBox(height: 12),
                            const Text('No events found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 6),
                            const Text('Tap "+ Create New Event" to start designing your smart invitation.',
                                textAlign: TextAlign.center, style: TextStyle(color: AppConstants.textMuted, fontSize: 13)),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Create New Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EventCreateScreen()));
                                if (created != null) _loadEvents();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final event = filtered[idx];
                      return _buildEventCard(event);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () async {
          final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EventCreateScreen()));
          if (created != null) _loadEvents();
        },
      ),
    );
  }

  // ══ Responsive Modern Event Card ════════════════════════════════════════
  Widget _buildEventCard(EventModel event) {
    final gpsUrl = event.googleMapsDirectionsUrl ??
        event.googleMapsUrl ??
        'https://maps.google.com/?q=${Uri.encodeComponent("${event.venueName} ${event.venueAddress}")}';

    // Status styling
    final status = event.statusText;
    final isLive = status.toLowerCase().contains('live');
    final statusBg = isLive ? const Color(0xFFDCFCE7) : const Color(0xFFEDE9FE);
    final statusColor = isLive ? const Color(0xFF16A34A) : AppConstants.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Banner Image with Occasion Badge & Status ──
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B0764), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  image: event.coverImageUrl != null && event.coverImageUrl!.startsWith('http')
                      ? DecorationImage(
                          image: NetworkImage(event.coverImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Top Occasion Badge
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(event.eventTypeIcon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        event.eventTypeName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              // Status Pill
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        status,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              // Title on Banner
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                      ),
                    ),
                    Text(
                      'Hosted by ${event.hostNames}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Event Details Row ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Date & Time
                    const Icon(Icons.calendar_today, size: 16, color: AppConstants.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      event.eventDate,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (event.eventTime != null) ...[
                      const SizedBox(width: 6),
                      Text('• ${event.eventTime}', style: const TextStyle(fontSize: 12, color: AppConstants.textMuted)),
                    ],
                    const Spacer(),
                    // Guest Capacity Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people, size: 13, color: Color(0xFFD97706)),
                          const SizedBox(width: 4),
                          Text(
                            '${event.guestCount}/${event.capacity} Guests',
                            style: const TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Venue Address with GPS Link
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: AppConstants.accentColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.venueName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          if (event.venueAddress.isNotEmpty)
                            Text(
                              event.venueAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 22),

                // ── Action Buttons Row: View, Edit, Share, Manage ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // View Button
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: AppConstants.primaryColor),
                        ),
                        icon: const Icon(Icons.remove_red_eye, size: 15, color: AppConstants.primaryColor),
                        label: const Text('View Card', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => InvitationCardViewScreen(event: event)),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Edit Button
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.edit, size: 15, color: Color(0xFF0284C7)),
                        label: const Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                        onPressed: () => _showQuickEdit(event),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Share Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.chat, size: 14),
                        label: const Text('Share', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () => _shareViaWhatsApp(event),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Manage Button
                    IconButton(
                      icon: const Icon(Icons.settings, color: AppConstants.textMuted),
                      tooltip: 'Manage',
                      onPressed: () => _showManageModal(event),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
