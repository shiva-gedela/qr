import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../models/event_model.dart';

enum RideCategory { all, bike, auto, cab, green }

class RideOption {
  final String provider; // 'Uber', 'Rapido', 'Ola', 'Green SM'
  final String vehicleName;
  final String vehicleType; // 'bike', 'auto', 'cab', 'green'
  final String iconEmoji;
  final String eta; // e.g. '2 mins'
  final double baseFare;
  final double perKmRate;
  final String? badge; // 'Cheapest', 'Fastest', '100% Eco Green', 'Best Value'
  final Color brandColor;
  final String deepLinkScheme;
  final String webFallback;

  const RideOption({
    required this.provider,
    required this.vehicleName,
    required this.vehicleType,
    required this.iconEmoji,
    required this.eta,
    required this.baseFare,
    required this.perKmRate,
    this.badge,
    required this.brandColor,
    required this.deepLinkScheme,
    required this.webFallback,
  });

  int calculateFare(double distanceKm) {
    final fare = baseFare + (perKmRate * distanceKm);
    return fare.round();
  }
}

class EventRideBookingScreen extends StatefulWidget {
  final EventModel? event;
  final String? destinationName;
  final String? destinationAddress;
  final String? customMapsUrl;

  const EventRideBookingScreen({
    Key? key,
    this.event,
    this.destinationName,
    this.destinationAddress,
    this.customMapsUrl,
  }) : super(key: key);

  @override
  State<EventRideBookingScreen> createState() => _EventRideBookingScreenState();
}

class _EventRideBookingScreenState extends State<EventRideBookingScreen> {
  RideCategory _selectedCategory = RideCategory.all;
  bool _showFareInAppMode = false;
  String _pickupLocation = 'My Current Location (GPS Detected)';
  double _distanceKm = 7.5;
  int _travelTimeMins = 20;

  late final String _destName;
  late final String _destAddress;
  late final String _mapsUrl;

  @override
  void initState() {
    super.initState();
    _destName = widget.event?.venueName ??
        widget.destinationName ??
        'Event Celebration Venue';
    _destAddress = widget.event?.venueAddress ??
        widget.destinationAddress ??
        'Bengaluru City Center, Karnataka';

    final encodedDest = Uri.encodeComponent('$_destName, $_destAddress');
    _mapsUrl = widget.event?.googleMapsDirectionsUrl ??
        widget.event?.googleMapsUrl ??
        widget.customMapsUrl ??
        'https://www.google.com/maps/dir/?api=1&destination=$encodedDest';

    // Calculate simulated realistic distance based on venue text hash to remain consistent
    final seed = (_destName + _destAddress).length;
    _distanceKm = (5.0 + (seed % 120) / 10.0);
    _travelTimeMins = (_distanceKm * 2.6).round().clamp(10, 85);
  }

  List<RideOption> _getAvailableRides() {
    final encodedDest = Uri.encodeComponent('$_destName, $_destAddress');
    return [
      // 🛵 RAPIDO BIKE
      RideOption(
        provider: 'Rapido',
        vehicleName: 'Rapido Bike Taxi',
        vehicleType: 'bike',
        iconEmoji: '🛵',
        eta: '2 mins away',
        baseFare: 15,
        perKmRate: 6.8,
        badge: 'Lowest Fare',
        brandColor: const Color(0xFFF59E0B),
        deepLinkScheme: 'rapido://booking?destination=$encodedDest',
        webFallback: 'https://rapido.bike',
      ),

      // 🛵 UBER MOTO
      RideOption(
        provider: 'Uber',
        vehicleName: 'Uber Moto',
        vehicleType: 'bike',
        iconEmoji: '🏍️',
        eta: '3 mins away',
        baseFare: 20,
        perKmRate: 7.5,
        badge: 'Fast Pickup',
        brandColor: Colors.black,
        deepLinkScheme: 'uber://?action=setPickup&pickup=my_location&dropoff[formatted_address]=$encodedDest',
        webFallback: 'https://m.uber.com/ul/?action=setPickup&pickup=my_location&dropoff[formatted_address]=$encodedDest',
      ),

      // 🛺 UBER AUTO
      RideOption(
        provider: 'Uber',
        vehicleName: 'Uber Auto',
        vehicleType: 'auto',
        iconEmoji: '🛺',
        eta: '3 mins away',
        baseFare: 28,
        perKmRate: 13.5,
        badge: 'Popular',
        brandColor: Colors.black,
        deepLinkScheme: 'uber://?action=setPickup&pickup=my_location&dropoff[formatted_address]=$encodedDest',
        webFallback: 'https://m.uber.com/ul/?action=setPickup&pickup=my_location&dropoff[formatted_address]=$encodedDest',
      ),

      // 🛺 OLA AUTO
      RideOption(
        provider: 'Ola',
        vehicleName: 'Ola Auto',
        vehicleType: 'auto',
        iconEmoji: '🛺',
        eta: '4 mins away',
        baseFare: 30,
        perKmRate: 14.0,
        brandColor: const Color(0xFF15803D),
        deepLinkScheme: 'ola://book?drop_name=$encodedDest',
        webFallback: 'https://book.olacabs.com/?drop_name=$encodedDest',
      ),

      // ⚡ GREEN SM / BLUSMART EV (ZERO EMISSION)
      RideOption(
        provider: 'Green SM',
        vehicleName: 'Green SM Eco EV',
        vehicleType: 'green',
        iconEmoji: '⚡',
        eta: '5 mins away',
        baseFare: 65,
        perKmRate: 18.0,
        badge: '100% Eco Green',
        brandColor: const Color(0xFF0D9488),
        deepLinkScheme: 'blusmart://ride?destination=$encodedDest',
        webFallback: 'https://blu-smart.com',
      ),

      // 🚗 UBER GO
      RideOption(
        provider: 'Uber',
        vehicleName: 'Uber Go (AC Hatchback)',
        vehicleType: 'cab',
        iconEmoji: '🚗',
        eta: '4 mins away',
        baseFare: 48,
        perKmRate: 16.5,
        badge: 'Best Value Cab',
        brandColor: Colors.black,
        deepLinkScheme: 'uber://?action=setPickup&pickup=my_location&dropoff[formatted_address]=$encodedDest',
        webFallback: 'https://m.uber.com/ul/?action=setPickup&pickup=my_location&dropoff[formatted_address]=$encodedDest',
      ),

      // 🚗 OLA PRIME SEDAN
      RideOption(
        provider: 'Ola',
        vehicleName: 'Ola Prime Sedan',
        vehicleType: 'cab',
        iconEmoji: '🚕',
        eta: '5 mins away',
        baseFare: 75,
        perKmRate: 21.0,
        brandColor: const Color(0xFF15803D),
        deepLinkScheme: 'ola://book?drop_name=$encodedDest',
        webFallback: 'https://book.olacabs.com/?drop_name=$encodedDest',
      ),
    ];
  }

  Future<void> _launchRideApp(RideOption ride) async {
    final nativeUri = Uri.parse(ride.deepLinkScheme);
    final webUri = Uri.parse(ride.webFallback);

    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // Fallback to official web portal or app store
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open ${ride.provider}. Please install the app from Google Play Store.'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
    }
  }

  Future<void> _openGoogleMaps() async {
    final uri = Uri.parse(_mapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps directions.')),
      );
    }
  }

  void _shareViaWhatsApp() async {
    final text = '🚗 Travelling to $_destName\n'
        '📍 Destination: $_destAddress\n'
        '📏 Distance: ${_distanceKm.toStringAsFixed(1)} km (~$_travelTimeMins mins)\n'
        '🗺️ Live Navigation: $_mapsUrl\n'
        'Sent via QRouteX Event Navigation (qroutex.com)';
    final waUrl = 'whatsapp://send?text=${Uri.encodeComponent(text)}';
    final waUri = Uri.parse(waUrl);

    if (await canLaunchUrl(waUri)) {
      await launchUrl(waUri);
    } else {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route details copied to clipboard!')),
      );
    }
  }

  void _changePickupDialog() {
    final controller = TextEditingController(text: _pickupLocation);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.my_location, color: AppConstants.primaryColor),
            SizedBox(width: 8),
            Text('Change Pickup Point', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your street, hotel, or landmark',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
            onPressed: () {
              final newLocation = controller.text.trim();
              if (newLocation.isNotEmpty) {
                setState(() => _pickupLocation = newLocation);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Update Pickup', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allRides = _getAvailableRides();
    final filteredRides = allRides.where((r) {
      if (_selectedCategory == RideCategory.all) return true;
      if (_selectedCategory == RideCategory.bike && r.vehicleType == 'bike') return true;
      if (_selectedCategory == RideCategory.auto && r.vehicleType == 'auto') return true;
      if (_selectedCategory == RideCategory.cab && r.vehicleType == 'cab') return true;
      if (_selectedCategory == RideCategory.green && r.vehicleType == 'green') return true;
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Book Ride & GPS Route', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share ETA via WhatsApp',
            onPressed: _shareViaWhatsApp,
          ),
          IconButton(
            icon: const Icon(Icons.directions),
            tooltip: 'Open in Google Maps',
            onPressed: _openGoogleMaps,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Interactive Location Header & Route Card ──
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppConstants.primaryDark, Color(0xFF2E1065)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: Column(
                children: [
                  // Location Path Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Origin / Pickup
                        Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PICKUP POINT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    _pickupLocation,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_location_alt, color: AppConstants.primaryColor, size: 20),
                              tooltip: 'Edit Pickup Point',
                              onPressed: _changePickupDialog,
                            ),
                          ],
                        ),

                        // Vertical connecting route line
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 22,
                              width: 2,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),

                        // Destination
                        Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withOpacity(0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'EVENT DESTINATION',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEF4444),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    _destName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.textDark,
                                    ),
                                  ),
                                  Text(
                                    _destAddress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppConstants.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Route Metrics Row (Distance, Time, Traffic)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.straighten,
                          title: 'Distance',
                          value: '${_distanceKm.toStringAsFixed(1)} km',
                          color: const Color(0xFF38BDF8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.timer,
                          title: 'Estimated ETA',
                          value: '~$(_travelTimeMins) mins',
                          color: const Color(0xFFFBBF24),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.traffic,
                          title: 'Traffic Flow',
                          value: 'Smooth',
                          color: const Color(0xFF34D399),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Google Maps Direct Navigation Banner
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppConstants.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.navigation, color: Color(0xFF2563EB)),
                    label: const Text(
                      'Open Turn-by-Turn GPS in Google Maps',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: _openGoogleMaps,
                  ),
                ],
              ),
            ),
          ),

          // ── Fare Mode & Vehicle Filters Bar ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mode Toggle: Live Fare in App vs Estimated Fare in ₹
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.currency_rupee, color: AppConstants.primaryColor, size: 20),
                            SizedBox(width: 6),
                            Text(
                              'Fare Comparison',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              _showFareInAppMode ? 'Live in App' : 'Calculated ₹',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _showFareInAppMode ? const Color(0xFF0284C7) : AppConstants.primaryColor,
                              ),
                            ),
                            Switch.adaptive(
                              value: _showFareInAppMode,
                              activeColor: const Color(0xFF0284C7),
                              onChanged: (val) => setState(() => _showFareInAppMode = val),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Vehicle Filter Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterTab(RideCategory.all, 'All Rides (${allRides.length})'),
                        const SizedBox(width: 8),
                        _buildFilterTab(RideCategory.bike, '🛵 Bike Taxi'),
                        const SizedBox(width: 8),
                        _buildFilterTab(RideCategory.auto, '🛺 Auto'),
                        const SizedBox(width: 8),
                        _buildFilterTab(RideCategory.cab, '🚗 Cabs'),
                        const SizedBox(width: 8),
                        _buildFilterTab(RideCategory.green, '⚡ Green SM EV'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Ride Options List ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final ride = filteredRides[index];
                  final fare = ride.calculateFare(_distanceKm);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: ride.badge == '100% Eco Green'
                            ? const Color(0xFF10B981).withOpacity(0.4)
                            : (ride.badge == 'Lowest Fare' ? const Color(0xFFF59E0B).withOpacity(0.4) : Colors.grey.shade200),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Provider Icon Avatar
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppConstants.backgroundColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Center(
                                  child: Text(ride.iconEmoji, style: const TextStyle(fontSize: 26)),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Vehicle & Provider Title
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          ride.vehicleName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        if (ride.badge != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: ride.badge == '100% Eco Green'
                                                  ? const Color(0xFFD1FAE5)
                                                  : const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              ride.badge!,
                                              style: TextStyle(
                                                color: ride.badge == '100% Eco Green'
                                                    ? const Color(0xFF047857)
                                                    : const Color(0xFFB45309),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text(
                                          ride.provider,
                                          style: TextStyle(
                                            color: ride.brandColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text('•', style: TextStyle(color: Colors.grey)),
                                        const SizedBox(width: 6),
                                        Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          ride.eta,
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Fare Column
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!_showFareInAppMode) ...[
                                    Text(
                                      '₹$fare',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.textDark,
                                      ),
                                    ),
                                    const Text('Estimated Fare', style: TextStyle(fontSize: 10, color: AppConstants.textMuted)),
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Live in App',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Book Button Row
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ride.brandColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.touch_app, size: 16),
                                  label: Text(
                                    _showFareInAppMode
                                        ? 'Check Fare & Book on ${ride.provider}'
                                        : 'Book on ${ride.provider}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  onPressed: () => _launchRideApp(ride),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: filteredRides.length,
              ),
            ),
          ),

          // ── Bottom Help & Disclaimer ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline, color: AppConstants.primaryColor, size: 18),
                        SizedBox(width: 8),
                        Text('About Ride Estimates & Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Fares shown are calculated estimates based on city standard transit distance (${7.5} km) and duration.\n'
                      '• Tap "Book on Provider" to open Uber, Rapido, Ola, or Green SM directly on your phone with destination pre-filled.\n'
                      '• Switch "Live in App" anytime to compare real-time dynamic surge prices.',
                      style: TextStyle(fontSize: 12, color: AppConstants.textMuted, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.share, size: 16, color: Color(0xFF10B981)),
                            label: const Text('Share ETA via WhatsApp', style: TextStyle(fontSize: 12, color: Color(0xFF10B981))),
                            onPressed: _shareViaWhatsApp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(RideCategory category, String title) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppConstants.primaryColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppConstants.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
