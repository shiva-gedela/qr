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
import 'event_ride_booking_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({Key? key}) : super(key: key);

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  late Future<List<EventModel>> _eventsFuture;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  bool _isGridView = true; // OLX marketplace 2-column grid mode default

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
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareViaWhatsApp(EventModel event) async {
    final message = event.shareMessage;
    final whatsappUrl = "whatsapp://send?text=${Uri.encodeComponent(message)}";
    final webUrl = "https://api.whatsapp.com/send?text=${Uri.encodeComponent(message)}";
    final waUri = Uri.parse(whatsappUrl);
    final webUri = Uri.parse(webUrl);

    if (await canLaunchUrl(waUri)) {
      await launchUrl(waUri);
    } else if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
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
                        Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('Manage invitation pass & details', style: const TextStyle(color: AppConstants.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.info_outline, color: AppConstants.primaryColor),
                title: const Text('View OLX-Style Option Details'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.directions_car, color: Color(0xFF15803D)),
                title: const Text('Book Ride & GPS Route'),
                subtitle: const Text('Uber • Rapido • Ola • Green SM', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => EventRideBookingScreen(event: event)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.card_membership, color: AppConstants.primaryColor),
                title: const Text('Digital Invitation Preview'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => InvitationCardViewScreen(event: event)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF0284C7)),
                title: const Text('Event Portfolio Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => EventPortfolioScreen(event: event)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Color(0xFF10B981)),
                title: const Text('Share via WhatsApp'),
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
          title: const Text('Edit Event Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                if (!mounted) return;
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text('Events & Invitations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: AppConstants.primaryDark,
        elevation: 0,
        actions: [
          // Toggle Grid / List View (OLX signature feature)
          IconButton(
            icon: Icon(_isGridView ? Icons.view_agenda : Icons.grid_view),
            tooltip: _isGridView ? 'Switch to List View' : 'Switch to OLX Grid View',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
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
          // ── Search & Filter Bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            color: Colors.white,
            child: Column(
              children: [
                // Search Input
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search celebrations, venues, hosts...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppConstants.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AppConstants.primaryColor, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                    filled: true,
                    fillColor: AppConstants.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((opt) {
                      final isSelected = _selectedFilter == opt['code'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          avatar: Text(opt['emoji']!, style: const TextStyle(fontSize: 12)),
                          label: Text(opt['label']!),
                          selected: isSelected,
                          selectedColor: AppConstants.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppConstants.textDark,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 11,
                          ),
                          onSelected: (_) => setState(() => _selectedFilter = opt['code']!),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Event Card Feed ──
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
                  final filtered = allEvents.where((e) {
                    final matchesCat = _selectedFilter == 'all' || e.eventType.toLowerCase() == _selectedFilter;
                    final q = _searchQuery.toLowerCase().trim();
                    final matchesSearch = q.isEmpty ||
                        e.title.toLowerCase().contains(q) ||
                        e.venueName.toLowerCase().contains(q) ||
                        e.venueAddress.toLowerCase().contains(q) ||
                        e.hostNames.toLowerCase().contains(q);
                    return matchesCat && matchesSearch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.celebration_outlined, size: 64, color: AppConstants.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty ? 'No events found' : 'No events match "$_searchQuery"',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Tap "+ Create New Event" to start designing your smart invitation.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppConstants.textMuted, fontSize: 13),
                            ),
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

                  // ── Render in OLX 2-Column Grid or List Mode ──
                  if (_isGridView) {
                    // Universal Mobile Responsive Grid
                    final crossAxisCount = screenWidth > 550 ? 3 : 2;
                    // Dynamic aspect ratio calculation to prevent any overflow on 320px - 480px devices
                    final dynamicAspectRatio = screenWidth < 340
                        ? 0.62
                        : screenWidth < 380
                            ? 0.66
                            : 0.70;

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: dynamicAspectRatio,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        return _buildOlxGridCard(filtered[idx]);
                      },
                    );
                  } else {
                    return ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        return _buildEventListCard(filtered[idx]);
                      },
                    );
                  }
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

  // ══ OLX 2-COLUMN MARKETPLACE CARD (Responsive & Fits Any Screen) ═══════════
  Widget _buildOlxGridCard(EventModel event) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Photo Area with Occasion Badge
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E1065), Color(0xFF4A148C), Color(0xFF5F259F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      image: event.coverImageUrl != null && event.coverImageUrl!.startsWith('http')
                          ? DecorationImage(image: NetworkImage(event.coverImageUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: event.coverImageUrl == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(event.eventTypeIcon, style: const TextStyle(fontSize: 32)),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.35),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    event.eventTypeName.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),

                  // Top Status Tag
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: event.isActive ? const Color(0xFF10B981) : Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        event.isActive ? 'VERIFIED' : 'STANDBY',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                      ),
                    ),
                  ),

                  // Photo counter pill
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_camera, size: 10, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            '1/${event.photos.length + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Body (OLX Marketplace Specs)
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price / Slots Display (Prominent OLX font)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '₹ Free Pass',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textDark,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${event.capacity} Slots',
                                style: const TextStyle(fontSize: 9, color: Color(0xFF047857), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Title (2 lines max)
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textDark,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),

                        // Host
                        Text(
                          'By ${event.hostNames}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: AppConstants.textMuted, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),

                    // Footer Location & Date (OLX signature footer)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 11, color: AppConstants.primaryColor),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                event.venueName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, color: AppConstants.textDark),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              event.eventDate,
                              style: const TextStyle(fontSize: 9, color: AppConstants.textMuted),
                            ),
                            const Icon(Icons.chevron_right, size: 14, color: AppConstants.textMuted),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══ DETAILED LIST CARD ════════════════════════════════════════════════════
  Widget _buildEventListCard(EventModel event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Area
          Stack(
            children: [
              Container(
                height: 130,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B0764), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  image: event.coverImageUrl != null && event.coverImageUrl!.startsWith('http')
                      ? DecorationImage(image: NetworkImage(event.coverImageUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(event.eventTypeIcon, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        event.eventTypeName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
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
                        fontSize: 16,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                      ),
                    ),
                    Text(
                      'Hosted by ${event.hostNames}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Details & Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: AppConstants.primaryColor),
                        const SizedBox(width: 4),
                        Text(event.eventDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${event.guestCount}/${event.capacity} Guests',
                        style: const TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppConstants.accentColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${event.venueName}, ${event.venueAddress}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: AppConstants.primaryColor),
                        ),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)));
                        },
                        child: const Text('Option Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: Color(0xFF15803D)),
                          foregroundColor: const Color(0xFF15803D),
                        ),
                        icon: const Icon(Icons.directions_car, size: 13),
                        label: const Text('Ride', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => EventRideBookingScreen(event: event)));
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
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
