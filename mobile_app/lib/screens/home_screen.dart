import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'events/event_list_screen.dart';
import 'events/event_create_screen.dart';
import 'events/event_detail_screen.dart';
import 'events/invitation_card_view_screen.dart';
import 'events/event_portfolio_screen.dart';
import 'events/event_ride_booking_screen.dart';
import 'business/business_list_screen.dart';
import 'qr/qr_scanner_screen.dart';
import 'qr/qr_display_screen.dart';
import 'auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  List<EventModel> _recentEvents = [];
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardEvents();
  }

  Future<void> _loadDashboardEvents() async {
    setState(() => _isLoadingEvents = true);
    try {
      final events = await ApiService.getEvents();
      if (!mounted) return;
      setState(() {
        _recentEvents = events;
        _isLoadingEvents = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingEvents = false);
    }
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showServerSettings() {
    final urlController = TextEditingController(text: AppConstants.baseUrl);
    bool testing = false;
    String? statusMsg;
    Color statusColor = Colors.grey;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.dns, color: AppConstants.primaryColor),
                  SizedBox(width: 8),
                  Text('Server Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Configure backend server address:', style: TextStyle(fontSize: 13, color: AppConstants.textMuted)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Server URL',
                      hintText: 'e.g. http://10.22.84.118:8000',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (statusMsg != null)
                    Text(statusMsg!, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: testing ? null : () async {
                    setDialogState(() {
                      testing = true;
                      statusMsg = 'Testing connection...';
                      statusColor = Colors.orange;
                    });
                    try {
                      await AppConstants.setBaseUrl(urlController.text.trim());
                      final events = await ApiService.getEvents();
                      setDialogState(() {
                        testing = false;
                        statusMsg = 'Connected successfully (${events.length} events found)';
                        statusColor = AppConstants.successColor;
                      });
                    } catch (e) {
                      setDialogState(() {
                        testing = false;
                        statusMsg = 'Connection failed: $e';
                        statusColor = AppConstants.dangerColor;
                      });
                    }
                  },
                  child: const Text('Test Connection'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
                  onPressed: () async {
                    await AppConstants.setBaseUrl(urlController.text.trim());
                    Navigator.pop(context);
                    _loadDashboardEvents();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Server settings saved!')),
                    );
                  },
                  child: const Text('Save & Apply', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ══ PhonePe Dashboard Body ═══════════════════════════════════════════════
  Widget _buildPhonePeDashboard() {
    return RefreshIndicator(
      color: AppConstants.primaryColor,
      onRefresh: _loadDashboardEvents,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Header Banner (PhonePe Purple Curve) ──
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppConstants.primaryColor, AppConstants.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // App Bar Row
                  Row(
                    children: [
                      // User Avatar (PhonePe style)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C4DFF), Color(0xFF5F259F)],
                            ),
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Location Pin (PhonePe Header style)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Text(
                                  'Your Location',
                                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                                Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                              ],
                            ),
                            Row(
                              children: const [
                                Icon(Icons.location_on, color: AppConstants.accentColor, size: 15),
                                SizedBox(width: 4),
                                Text(
                                  'GPS Enabled & Ready',
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Action Icons: Scanner & Settings
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
                        tooltip: 'Scan QR',
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune, color: Colors.white, size: 24),
                        tooltip: 'Settings',
                        onPressed: _showServerSettings,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Search & Scan Bar ──
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.search, color: AppConstants.primaryColor, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Scan any Event QR or Search Occasion...',
                              style: TextStyle(color: AppConstants.textMuted, fontSize: 13),
                            ),
                          ),
                          Icon(Icons.qr_code_2, color: AppConstants.primaryColor, size: 22),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── PhonePe Quick Actions Card ("Transfer Money" style) ──
            Transform.translate(
              offset: const Offset(0, -12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickActionItem(
                        icon: Icons.qr_code_scanner,
                        label: 'Scan Any QR',
                        bgColor: AppConstants.purpleSurface,
                        iconColor: AppConstants.primaryColor,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
                        },
                      ),
                      _buildQuickActionItem(
                        icon: Icons.add_circle,
                        label: 'Create Event',
                        bgColor: const Color(0xFFE0F2FE),
                        iconColor: const Color(0xFF0284C7),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EventCreateScreen()));
                        },
                      ),
                      _buildQuickActionItem(
                        icon: Icons.directions_car,
                        label: 'Book Ride',
                        bgColor: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFD97706),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventRideBookingScreen(
                                event: _recentEvents.isNotEmpty ? _recentEvents.first : null,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildQuickActionItem(
                        icon: Icons.mark_email_read,
                        label: 'My Invites',
                        bgColor: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF16A34A),
                        onTap: () {
                          setState(() => _currentNavIndex = 1);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── PhonePe Promo Banner ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E1065), Color(0xFF5F259F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppConstants.accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.near_me, color: Colors.black87, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'No More Lost Guests! 🗺️',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Turn-by-turn Google Maps GPS route navigation integrated into every event QR.',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Event Occasions Grid (PhonePe "Recharge & Pay Bills" Style) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Event Occasions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppConstants.textDark),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.purpleSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Instant QR Codes',
                      style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                  children: [
                    _buildOccasionTile(
                      emoji: '💍',
                      title: 'Wedding',
                      color: const Color(0xFFFCE7F3),
                      code: 'wedding',
                    ),
                    _buildOccasionTile(
                      emoji: '🎂',
                      title: 'Birthday',
                      color: const Color(0xFFFEF3C7),
                      code: 'birthday',
                    ),
                    _buildOccasionTile(
                      emoji: '💑',
                      title: 'Engagement',
                      color: const Color(0xFFEDE9FE),
                      code: 'engagement',
                    ),
                    _buildOccasionTile(
                      emoji: '❤️',
                      title: 'Anniversary',
                      color: const Color(0xFFFFE4E6),
                      code: 'anniversary',
                    ),
                    _buildOccasionTile(
                      emoji: '🏠',
                      title: 'Housewarming',
                      color: const Color(0xFFE0E7FF),
                      code: 'housewarming',
                    ),
                    _buildOccasionTile(
                      emoji: '🎓',
                      title: 'Graduation',
                      color: const Color(0xFFDCFCE7),
                      code: 'graduation',
                    ),
                  ],
                ),
              ),
            ),

            // ── Recent Events & Invitations (PhonePe "Recent Transactions" Style) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Events & Routes',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppConstants.textDark),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentNavIndex = 1),
                    child: const Text('View All', style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            if (_isLoadingEvents)
              const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()))
            else if (_recentEvents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.celebration_outlined, size: 48, color: AppConstants.textMuted),
                      const SizedBox(height: 8),
                      const Text('No celebrations created yet.', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Tap "Create Event" to design your first QR invitation.', style: TextStyle(color: AppConstants.textMuted, fontSize: 12)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EventCreateScreen()));
                        },
                        child: const Text('Create Event Now', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: _recentEvents.take(4).map((event) {
                    final gpsUrl = event.googleMapsDirectionsUrl ?? event.googleMapsUrl ?? 'https://maps.google.com/?q=${Uri.encodeComponent("${event.venueName} ${event.venueAddress}")}';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Occasion Icon Circle
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
                                    Text(
                                      event.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 13, color: AppConstants.primaryColor),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            event.venueName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: AppConstants.textMuted),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // QR Code Button
                              IconButton(
                                icon: const Icon(Icons.qr_code_2, color: AppConstants.primaryColor, size: 28),
                                tooltip: 'View QR',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => QrDisplayScreen(
                                        title: event.title,
                                        subtitle: 'Event QR & GPS Navigation',
                                        qrData: event.targetUrl ?? '${AppConstants.baseUrl}/events/e/${event.slug}/',
                                        qrImageUrl: event.qrImageUrl,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          // Action Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                event.eventDate,
                                style: const TextStyle(fontSize: 12, color: AppConstants.textMuted, fontWeight: FontWeight.w500),
                              ),
                              Row(
                                children: [
                                  // Book Ride & GPS Route Button
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppConstants.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    icon: const Icon(Icons.directions_car, size: 14),
                                    label: const Text('Book Ride & GPS'),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EventRideBookingScreen(event: event),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  // Detail Button
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      side: const BorderSide(color: AppConstants.primaryColor),
                                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => InvitationCardViewScreen(event: event)),
                                      );
                                    },
                                    child: const Text('View Card'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 80), // Padding for bottom nav & FAB
          ],
        ),
      ),
    );
  }

  // Quick Action Circular Item (PhonePe Style)
  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppConstants.textDark),
          ),
        ],
      ),
    );
  }

  // Occasion Tile (PhonePe "Recharge & Bills" Style)
  Widget _buildOccasionTile({
    required String emoji,
    required String title,
    required Color color,
    required String code,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventCreateScreen(initialEventType: code),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.textDark),
          ),
        ],
      ),
    );
  }

  // ══ Profile / Account Tab (PhonePe Style) ════════════════════════════════
  Widget _buildAccountTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppConstants.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 34),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('QRouteX User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(height: 2),
                      Text('GPS Smart Event QR Hub', style: TextStyle(color: AppConstants.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Settings list
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dns, color: AppConstants.primaryColor),
                  title: const Text('Backend Server Settings'),
                  subtitle: Text(AppConstants.baseUrl, style: const TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showServerSettings,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.login, color: AppConstants.primaryColor),
                  title: const Text('Sign In or Register Account'),
                  subtitle: const Text('Sync your celebrations across devices', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.public, color: AppConstants.primaryColor),
                  title: const Text('Official Website'),
                  subtitle: const Text('https://qroutex.com', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _openUrl('https://qroutex.com'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildPhonePeDashboard(),
      const EventListScreen(),
      const BusinessListScreen(),
      _buildAccountTab(),
    ];

    return Scaffold(
      body: SafeArea(
        top: false,
        child: pages[_currentNavIndex],
      ),
      // ── PhonePe Elevated Center QR Scanner Button ──
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppConstants.primaryColor,
        elevation: 6,
        tooltip: 'Scan Any QR Code',
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF7C4DFF), Color(0xFF5F259F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
        ),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // ── PhonePe Bottom Navigation Bar ──
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 12,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(index: 0, icon: Icons.home, label: 'Home'),
            _buildNavItem(index: 1, icon: Icons.celebration, label: 'Events'),
            const SizedBox(width: 48), // Space for centered FAB
            _buildNavItem(index: 2, icon: Icons.storefront, label: 'Vendors'),
            _buildNavItem(index: 3, icon: Icons.person, label: 'Account'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData icon, required String label}) {
    final isSelected = _currentNavIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentNavIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppConstants.primaryColor : AppConstants.textMuted,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppConstants.primaryColor : AppConstants.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
