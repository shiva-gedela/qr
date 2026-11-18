import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../models/event_model.dart';
import '../models/business_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'events/event_list_screen.dart';
import 'events/event_create_screen.dart';
import 'events/event_detail_screen.dart';
import 'events/invitation_card_view_screen.dart';
import 'events/event_portfolio_screen.dart';
import 'events/event_ride_booking_screen.dart';
import 'business/business_list_screen.dart';
import 'business/business_detail_screen.dart';
import 'business/vendor_add_screen.dart';
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
  List<BusinessModel> _featuredVendors = [];
  bool _isLoadingEvents = true;
  String _selectedCity = 'Bengaluru, KA';

  final List<String> _popularCities = [
    'Bengaluru, KA',
    'Mumbai, MH',
    'Delhi NCR',
    'Hyderabad, TS',
    'Chennai, TN',
    'Pune, MH',
    'Kolkata, WB',
    'Ahmedabad, GJ',
    'Jaipur, RJ',
    'Chandigarh, PB',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoadingEvents = true);
    try {
      final results = await Future.wait([
        ApiService.getEvents(),
        ApiService.getBusinesses(),
      ]);
      if (!mounted) return;
      setState(() {
        _recentEvents = results[0] as List<EventModel>;
        _featuredVendors = results[1] as List<BusinessModel>;
        _isLoadingEvents = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingEvents = false);
    }
  }

  void _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Your Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Personalize events & verified vendors in your region:', style: TextStyle(color: AppConstants.textMuted, fontSize: 13)),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: _popularCities.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final city = _popularCities[idx];
                    final isSelected = city == _selectedCity;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.location_on,
                        color: isSelected ? AppConstants.primaryColor : Colors.grey,
                      ),
                      title: Text(
                        city,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppConstants.primaryColor : AppConstants.textDark,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppConstants.primaryColor) : null,
                      onTap: () {
                        setState(() => _selectedCity = city);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: testing
                      ? null
                      : () async {
                          setDialogState(() {
                            testing = true;
                            statusMsg = 'Testing connection...';
                            statusColor = Colors.blue;
                          });
                          final ok = await ApiService.testConnection(urlController.text.trim());
                          setDialogState(() {
                            testing = false;
                            statusMsg = ok ? '✓ Backend Connected Successfully' : '✗ Server Unreachable';
                            statusColor = ok ? Colors.green : Colors.red;
                          });
                        },
                  child: const Text('Test Ping'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
                  onPressed: () async {
                    await AppConstants.setBaseUrl(urlController.text.trim());
                    if (!mounted) return;
                    Navigator.pop(context);
                    _loadDashboardData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Server updated: ${AppConstants.baseUrl}')),
                    );
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ══ OLX & PHONEPE HYBRID DASHBOARD ═════════════════════════════════════════
  Widget _buildDashboard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return RefreshIndicator(
      color: AppConstants.primaryColor,
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Header Banner (QRouteX Brand & OLX City Selector) ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
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
                  // App Bar Row with City Switcher
                  Row(
                    children: [
                      // App Logo (Official QRouteX Badge)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: AppConstants.accentColor, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(2),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/app_logo_symbol.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/app_logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Brand & OLX City Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  AppConstants.appName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppConstants.accentColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'PRO',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // OLX Location Selector Chip
                            GestureDetector(
                              onTap: _showCityPicker,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on, color: AppConstants.accentColor, size: 13),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      _selectedCity,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Scanner & Settings
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
                        tooltip: 'Scan QR',
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune, color: Colors.white, size: 22),
                        tooltip: 'Settings',
                        onPressed: _showServerSettings,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── OLX-Style Search & Scan Bar ──
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                          Icon(Icons.search, color: AppConstants.primaryColor, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Find celebrations, vendors, scan QR pass...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

            // ── Quick Actions Card ──
            Transform.translate(
              offset: const Offset(0, -12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
                        label: 'Scan QR',
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
                        onTap: () async {
                          final created = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EventCreateScreen()),
                          );
                          if (created != null) _loadDashboardData();
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
                        icon: Icons.add_business,
                        label: 'Add Vendor',
                        bgColor: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF16A34A),
                        onTap: () async {
                          final created = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const VendorAddScreen()),
                          );
                          if (created != null) _loadDashboardData();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Event Occasions (PhonePe & OLX Categories Style) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Event Occasions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppConstants.textDark),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppConstants.purpleSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Instant Passes',
                      style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
                  ],
                ),
                child: GridView.count(
                  crossAxisCount: screenWidth > 500 ? 6 : 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 10,
                  childAspectRatio: isSmallScreen ? 0.90 : 0.98,
                  children: [
                    _buildOccasionTile(emoji: '💍', title: 'Wedding', color: const Color(0xFFFCE7F3), code: 'wedding'),
                    _buildOccasionTile(emoji: '🎂', title: 'Birthday', color: const Color(0xFFFEF3C7), code: 'birthday'),
                    _buildOccasionTile(emoji: '💑', title: 'Engagement', color: const Color(0xFFEDE9FE), code: 'engagement'),
                    _buildOccasionTile(emoji: '❤️', title: 'Anniversary', color: const Color(0xFFFFE4E6), code: 'anniversary'),
                    _buildOccasionTile(emoji: '🏠', title: 'Housewarming', color: const Color(0xFFE0E7FF), code: 'housewarming'),
                    _buildOccasionTile(emoji: '🎓', title: 'Graduation', color: const Color(0xFFDCFCE7), code: 'graduation'),
                  ],
                ),
              ),
            ),

            // ── Recent Celebrations (OLX Marketplace Cards) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Celebrations',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppConstants.textDark),
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
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const Icon(Icons.celebration_outlined, size: 48, color: AppConstants.textMuted),
                      const SizedBox(height: 8),
                      const Text('No celebrations created yet.', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Tap "Create Event" to design your first smart QR invitation.', style: TextStyle(color: AppConstants.textMuted, fontSize: 12)),
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
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: _recentEvents.take(4).map((event) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              // Occasion Avatar
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
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            event.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppConstants.textDark),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD1FAE5),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${event.capacity} Slots',
                                            style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 9),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 12, color: AppConstants.primaryColor),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            event.venueName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                event.eventDate,
                                style: const TextStyle(fontSize: 11, color: AppConstants.textMuted, fontWeight: FontWeight.w500),
                              ),
                              Row(
                                children: [
                                  // Option Details Button (OLX style)
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      side: const BorderSide(color: AppConstants.primaryColor),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
                                      );
                                    },
                                    child: const Text('Option Details', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                                  ),
                                  const SizedBox(width: 6),
                                  // Ride Booking
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF15803D),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.directions_car, size: 12),
                                    label: const Text('Ride', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => EventRideBookingScreen(event: event)),
                                      );
                                    },
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

            // ── Verified Event Vendors (OLX Spotlight) ──
            if (_featuredVendors.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Verified Event Vendors',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppConstants.textDark),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _currentNavIndex = 2),
                      child: const Text('View All', style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _featuredVendors.take(5).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, idx) {
                    final b = _featuredVendors[idx];
                    return Container(
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => BusinessDetailScreen(business: b)),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              height: 70,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF2E1065), Color(0xFF5F259F)],
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(b.categoryEmoji, style: const TextStyle(fontSize: 30)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          b.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                      const Icon(Icons.verified, color: Color(0xFF0284C7), size: 12),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    b.categoryTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10, color: AppConstants.primaryColor, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '📍 ${b.city.isNotEmpty ? b.city : "Bengaluru"}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 9, color: AppConstants.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // Quick Action Circular Item
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
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

  // Occasion Tile
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
          MaterialPageRoute(builder: (_) => EventCreateScreen(initialEventType: code)),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConstants.textDark),
          ),
        ],
      ),
    );
  }

  // ══ Profile / Account Tab ════════════════════════════════════════════════
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
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: AppConstants.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('QRouteX User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(height: 2),
                      Text('Smart Event QR & Marketplace Hub', style: TextStyle(color: AppConstants.textMuted, fontSize: 13)),
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
                  leading: const Icon(Icons.add_business, color: Color(0xFF10B981)),
                  title: const Text('Add Event Vendor Profile'),
                  subtitle: const Text('List your catering, photography, decor, or venue services', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorAddScreen()));
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
      _buildDashboard(),
      const EventListScreen(),
      const BusinessListScreen(),
      _buildAccountTab(),
    ];

    return Scaffold(
      body: SafeArea(
        top: false,
        child: pages[_currentNavIndex],
      ),
      // Centered QR Scanner Button
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
      // Bottom Navigation Bar
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
