import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../models/event_model.dart';
import '../models/business_model.dart';
import '../models/booking_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'events/event_list_screen.dart';
import 'events/event_create_screen.dart';
import 'events/event_detail_screen.dart';
import 'events/invitation_card_view_screen.dart';
import 'events/event_portfolio_screen.dart';
import 'events/event_ride_booking_screen.dart';
import 'business/business_list_screen.dart';
import 'business/business_detail_screen.dart';
import 'business/vendor_add_screen.dart';
import 'booking/business_booking_screen.dart';
import 'booking/my_bookings_screen.dart';
import 'social/social_feed_screen.dart';
import 'social/create_post_screen.dart';
import 'profile/user_profile_screen.dart';
import 'profile/qr_tickets_wallet_screen.dart';
import 'qr/qr_scanner_screen.dart';
import 'qr/qr_history_screen.dart';
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
  List<BookingModel> _userBookings = [];
  bool _isLoadingDashboard = true;
  String _selectedCity = 'Bengaluru, KA';
  bool _isDetectingLocation = false;
  String _citySearchQuery = '';

  final Map<String, String> _stateCodes = {
    'karnataka': 'KA',
    'telangana': 'TS',
    'maharashtra': 'MH',
    'tamil nadu': 'TN',
    'delhi': 'DL',
    'andhra pradesh': 'AP',
    'west bengal': 'WB',
    'gujarat': 'GJ',
    'rajasthan': 'RJ',
    'punjab': 'PB',
    'kerala': 'KL',
    'uttar pradesh': 'UP',
    'goa': 'GA',
    'haryana': 'HR',
    'madhya pradesh': 'MP',
    'odisha': 'OD',
  };

  final List<String> _popularCities = [
    'Bengaluru, KA',
    'Hyderabad, TS',
    'Mumbai, MH',
    'Delhi NCR',
    'Chennai, TN',
    'Pune, MH',
    'Visakhapatnam, AP',
    'Kolkata, WB',
    'Ahmedabad, GJ',
    'Jaipur, RJ',
    'Chandigarh, PB',
    'Kochi, KL',
    'Goa, GA',
    'Lucknow, UP',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedCity();
    _loadDashboardData();
  }

  Future<void> _loadSavedCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('qroutex_selected_city');
      if (saved != null && saved.isNotEmpty && mounted) {
        setState(() => _selectedCity = saved);
      }
    } catch (_) {}
  }

  Future<void> _detectLiveLocation(StateSetter setModalState) async {
    setModalState(() => _isDetectingLocation = true);
    try {
      final res = await http.get(Uri.parse('https://get.geojs.io/v1/ip/geo.json')).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final city = data['city'] ?? 'Bengaluru';
        final region = (data['region'] ?? '').toString().toLowerCase();
        final stateCode = _stateCodes[region] ?? (region.isNotEmpty ? region.substring(0, 2).toUpperCase() : 'IN');
        final formatted = '$city, $stateCode';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('qroutex_selected_city', formatted);

        if (mounted) {
          setState(() {
            _selectedCity = formatted;
            _isDetectingLocation = false;
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('📍 Live Location: $formatted', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setModalState(() => _isDetectingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not detect live location. Please select your city from the list.'),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoadingDashboard = true);
    try {
      final results = await Future.wait([
        ApiService.getEvents(),
        ApiService.getBusinesses(),
        ApiService.getUserBookings(),
      ]);
      if (!mounted) return;
      setState(() {
        _recentEvents = results[0] as List<EventModel>;
        _featuredVendors = results[1] as List<BusinessModel>;
        _userBookings = results[2] as List<BookingModel>;
        _isLoadingDashboard = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingDashboard = false);
    }
  }

  void _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showCityPicker() {
    _citySearchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredCities = _popularCities.where((c) {
              if (_citySearchQuery.isEmpty) return true;
              return c.toLowerCase().contains(_citySearchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on, color: AppConstants.secondaryColor),
                          SizedBox(width: 8),
                          Text(
                            'Select Your City',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Personalize events, restaurants & verified vendors:',
                    style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  // 1. Use My Current Live Location (GPS) Action
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      onPressed: _isDetectingLocation ? null : () => _detectLiveLocation(setModalState),
                      icon: _isDetectingLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, color: Colors.white),
                      label: Text(
                        _isDetectingLocation ? 'Detecting Live Location...' : 'Use My Current Live Location (GPS)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search city or state...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppConstants.textMuted),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppConstants.textMuted),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() => _citySearchQuery = val);
                    },
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'POPULAR CITIES',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConstants.textMuted, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),

                  Expanded(
                    child: filteredCities.isEmpty
                        ? const Center(
                            child: Text('No cities match your search', style: TextStyle(color: AppConstants.textMuted)),
                          )
                        : ListView.separated(
                            itemCount: filteredCities.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final city = filteredCities[idx];
                              final isSelected = city == _selectedCity;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.pin_drop,
                                  color: isSelected ? AppConstants.primaryColor : Colors.grey.shade400,
                                ),
                                title: Text(
                                  city,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? AppConstants.primaryColor : AppConstants.textDark,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle, color: AppConstants.primaryColor)
                                    : null,
                                onTap: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('qroutex_selected_city', city);
                                  setState(() => _selectedCity = city);
                                  if (mounted) Navigator.pop(context);
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
      },
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.notifications, color: AppConstants.primaryColor),
                      SizedBox(width: 8),
                      Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppConstants.purpleSurface,
                  child: Icon(Icons.qr_code, color: AppConstants.primaryColor),
                ),
                title: const Text('Smart QR Check-in Ready', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Offline verification is active for upcoming celebrations.', style: TextStyle(fontSize: 12)),
                trailing: const Text('Now', style: TextStyle(fontSize: 11, color: AppConstants.textMuted)),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEF3C7),
                  child: Icon(Icons.directions_car, color: Color(0xFFD97706)),
                ),
                title: const Text('Ride Comparison Enabled', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Compare Uber, Rapido, and Ola fares for all venue destinations.', style: TextStyle(fontSize: 12)),
                trailing: const Text('1h ago', style: TextStyle(fontSize: 11, color: AppConstants.textMuted)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
                onPressed: () => Navigator.pop(context),
                child: const Text('Dismiss All', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  // Floating Create Action Modal Bottom Sheet
  void _showCreateActionsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Quick Actions',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Create celebrations, scan invitations, or book services',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppConstants.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.celebration, color: AppConstants.primaryColor),
                  ),
                  title: const Text('Create Smart Event', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('8-step wizard with digital QR invitations & portfolio', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EventCreateScreen()),
                    ).then((_) => _loadDashboardData());
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: Color(0xFF0284C7)),
                  ),
                  title: const Text('Scan QR Code', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Scan from camera or upload screenshot from gallery', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.restaurant, color: Color(0xFFD97706)),
                  ),
                  title: const Text('Book Table or Reserve Service', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Browse verified restaurants, salons, and banquet halls', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    if (_featuredVendors.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BusinessBookingScreen(business: _featuredVendors.first),
                        ),
                      ).then((_) => _loadDashboardData());
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BusinessListScreen()),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE7F3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_camera, color: Color(0xFFDB2777)),
                  ),
                  title: const Text('Share Celebration Moment', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Post event photos and video highlights to social feed', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storefront, color: Color(0xFF16A34A)),
                  ),
                  title: const Text('Register as Event Vendor', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('List catering, decor, photography or venue services', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VendorAddScreen()),
                    ).then((_) => _loadDashboardData());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ══ DASHBOARD TAB (HOME) ═════════════════════════════════════════════════
  Widget _buildHomeDashboard() {
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
            // ── Top Gradient Header with QRouteX Branding & Location ──
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
                  Row(
                    children: [
                      // App Logo (High-Res Rounded Squircle Badge)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.primaryColor.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.qr_code_2,
                              color: AppConstants.primaryColor,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Brand & City Dropdown
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
                            // Location Selector Chip
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

                      // Social Moments Feed Shortcut
                      IconButton(
                        icon: const Icon(Icons.dynamic_feed, color: Colors.white, size: 22),
                        tooltip: 'Moments Feed',
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SocialFeedScreen()));
                        },
                      ),

                      // Notifications Icon
                      IconButton(
                        icon: const Stack(
                          children: [
                            Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: CircleAvatar(
                                radius: 4,
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                        tooltip: 'Notifications',
                        onPressed: _showNotificationsSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Search & Scan Bar ──
                  GestureDetector(
                    onTap: () {
                      setState(() => _currentNavIndex = 1);
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
                        children: [
                          const Icon(Icons.search, color: AppConstants.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Search celebrations, vendors, scan pass...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: AppConstants.textMuted, fontSize: 13),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
                            },
                            child: const Icon(Icons.qr_code_scanner, color: AppConstants.primaryColor, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Quick Actions Bar ──
            Transform.translate(
              offset: const Offset(0, -12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
                        icon: Icons.add_circle_outline,
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
                        icon: Icons.restaurant_outlined,
                        label: 'Book Service',
                        bgColor: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFD97706),
                        onTap: () {
                          setState(() => _currentNavIndex = 3);
                        },
                      ),
                      _buildQuickActionItem(
                        icon: Icons.directions_car,
                        label: 'Book Ride',
                        bgColor: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF16A34A),
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
                        icon: Icons.camera_alt_outlined,
                        label: 'Moments',
                        bgColor: const Color(0xFFFCE7F3),
                        iconColor: const Color(0xFFDB2777),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SocialFeedScreen()));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Active Booking / Reservation Alert (If Any) ──
            if (_userBookings.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF064E3B), Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bookmark_added, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upcoming: ${_userBookings.first.businessName}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              '${_userBookings.first.serviceName} • ${_userBookings.first.bookingDate} at ${_userBookings.first.bookingTime}',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF047857),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => setState(() => _currentNavIndex = 3),
                        child: const Text('Manage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── Featured Events Carousel / Hero ──
            if (_recentEvents.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Featured Celebrations',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppConstants.textDark),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _currentNavIndex = 1),
                      child: const Text('View All', style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _recentEvents.take(5).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, idx) {
                    final event = _recentEvents[idx];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
                        );
                      },
                      child: Container(
                        width: 260,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppConstants.accentColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${event.eventTypeIcon} ${event.eventType.toUpperCase()}',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${event.capacity} Slots',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '📍 ${event.venueName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  event.eventDate,
                                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppConstants.primaryDark,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => InvitationCardViewScreen(event: event)),
                                    );
                                  },
                                  child: const Text('Digital Pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // ── Event Occasions (Quick Creator) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

            // ── Recent Celebrations (Option Details OLX Cards) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Celebrations',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppConstants.textDark),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentNavIndex = 1),
                    child: const Text('View All', style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            if (_isLoadingDashboard)
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

            // ── Verified Event Vendors & Local Services ──
            if (_featuredVendors.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Verified Event Vendors & Services',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppConstants.textDark),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BusinessListScreen()),
                        );
                      },
                      child: const Text('View All', style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _featuredVendors.take(5).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, idx) {
                    final b = _featuredVendors[idx];
                    return Container(
                      width: 170,
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
                              height: 65,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(b.categoryEmoji, style: const TextStyle(fontSize: 28)),
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
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '⭐ ${b.rating.toStringAsFixed(1)}',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEDE9FE),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('Book', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                                      ),
                                    ],
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

            // ── GPS Turn-by-Turn Navigation Promo Card ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppConstants.accentColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.navigation, color: AppConstants.accentColor, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Turn-by-Turn GPS Navigation',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'All QRouteX passes include live route directions & Uber / Ola / Rapido comparison.',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppConstants.textDark),
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
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

  // ══ MAIN SCAFFOLD WITH 5-TAB NOTCHED NAVIGATION ══════════════════════════
  @override
  Widget build(BuildContext context) {
    // 5 Primary Navigation Screens:
    // Tab 0: Home Dashboard
    // Tab 1: Explore (All Events & Vendors)
    // Tab 2: Create Action Modal (FAB center)
    // Tab 3: Bookings (My Bookings)
    // Tab 4: Profile (User Profile & Settings)
    final List<Widget> pages = [
      _buildHomeDashboard(),
      const EventListScreen(),
      const SizedBox.shrink(), // Center placeholder triggered via FAB
      const MyBookingsScreen(),
      const UserProfileScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        top: false,
        child: pages[_currentNavIndex],
      ),
      // Centered Floating Create (+) Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppConstants.primaryColor,
        elevation: 6,
        tooltip: 'Create or Scan',
        onPressed: _showCreateActionsModal,
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // 5-Tab Bottom App Bar
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 12,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(index: 0, icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
            _buildNavItem(index: 1, icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Explore'),
            const SizedBox(width: 48), // Center spacing for FloatingActionButton
            _buildNavItem(index: 3, icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Bookings'),
            _buildNavItem(index: 4, icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _currentNavIndex = index);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
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
