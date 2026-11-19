import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../models/event_model.dart';
import 'invitation_card_view_screen.dart';
import 'event_portfolio_screen.dart';
import 'event_ride_booking_screen.dart';
import 'event_analytics_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isFavorite = false;
  bool _isDescriptionExpanded = false;

  void _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareViaWhatsApp() async {
    final message = widget.event.shareMessage;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    final gpsUrl = event.googleMapsDirectionsUrl ??
        event.googleMapsUrl ??
        'https://maps.google.com/?q=${Uri.encodeComponent("${event.venueName} ${event.venueAddress}")}';

    // Simulated realistic distance
    final seed = (event.venueName + event.venueAddress).length;
    final distanceKm = (5.0 + (seed % 120) / 10.0).toStringAsFixed(1);
    final travelMins = ((double.tryParse(distanceKm) ?? 7.5) * 2.6).round().clamp(10, 85);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      // ── Custom App Bar with OLX Favorite & Share Actions ──
      appBar: AppBar(
        title: Text(
          event.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppConstants.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.redAccent : Colors.white,
            ),
            tooltip: 'Favorite',
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFavorite ? 'Saved to Favorites' : 'Removed from Favorites'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Check-in Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EventAnalyticsScreen(event: event)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: _shareViaWhatsApp,
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: 'Portfolio Gallery',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EventPortfolioScreen(event: event)),
              );
            },
          ),
        ],
      ),

      // ── Main Content Body ──
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── OLX-Style Hero Banner Carousel Box ──
            Stack(
              children: [
                Container(
                  height: isSmallScreen ? 200 : 230,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E1065), Color(0xFF4A148C), Color(0xFF5F259F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    image: event.coverImageUrl != null
                        ? DecorationImage(image: NetworkImage(event.coverImageUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: event.coverImageUrl == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(event.eventTypeIcon, style: const TextStyle(fontSize: 54)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  event.eventTypeName.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(color: Colors.black.withOpacity(0.2)),
                ),

                // Top Status Badge (OLX Featured / Verified Tag)
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppConstants.accentColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified, size: 14, color: Colors.black),
                        SizedBox(width: 4),
                        Text(
                          'VERIFIED PASS',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Right Photo Counter Pill (e.g. 📷 1/4)
                Positioned(
                  bottom: 12,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_camera, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '1 / ${event.photos.length + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── OLX Price, Title & Location Box ──
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prominent Pass/Pricing Highlight
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '₹ Free Guest Pass',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${event.capacity} Slots',
                              style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        event.statusText.toUpperCase(),
                        style: TextStyle(
                          color: event.isActive ? const Color(0xFF10B981) : AppConstants.textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Event Title
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Host Subtitle
                  Text(
                    'Hosted by ${event.hostNames}',
                    style: const TextStyle(color: AppConstants.textMuted, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 10),

                  // Location & Time row (OLX Footer item)
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppConstants.primaryColor, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${event.venueName}, ${event.venueAddress}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppConstants.textDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.grey, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Event Date: ${event.eventDate} • ${event.eventTime ?? "07:00 PM onwards"}',
                        style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── THE ICONIC OLX "OPTION DETAILS" SPECIFICATIONS GRID ──
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.tune, color: AppConstants.primaryColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Option Details & Overview',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Responsive 2-Column Parameter Grid (Fits any mobile screen)
                  GridView.count(
                    crossAxisCount: screenWidth > 500 ? 3 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: screenWidth < 340 ? 2.1 : (isSmallScreen ? 2.3 : 2.5),
                    children: [
                      _buildOlxOptionChip(
                        icon: Icons.celebration,
                        label: 'Occasion',
                        value: event.eventTypeName,
                        color: const Color(0xFF7C4DFF),
                      ),
                      _buildOlxOptionChip(
                        icon: Icons.calendar_month,
                        label: 'Date',
                        value: event.eventDate,
                        color: const Color(0xFF0284C7),
                      ),
                      _buildOlxOptionChip(
                        icon: Icons.schedule,
                        label: 'Time',
                        value: event.eventTime ?? '07:00 PM',
                        color: const Color(0xFFF59E0B),
                      ),
                      _buildOlxOptionChip(
                        icon: Icons.people,
                        label: 'Guest Limit',
                        value: '${event.capacity} Passes',
                        color: const Color(0xFF10B981),
                      ),
                      _buildOlxOptionChip(
                        icon: Icons.how_to_reg,
                        label: 'Confirmed',
                        value: '${event.guestCount} Attending',
                        color: const Color(0xFF6366F1),
                      ),
                      _buildOlxOptionChip(
                        icon: Icons.checkroom,
                        label: 'Dress Code',
                        value: event.dressCode ?? 'Festive / Ethnic',
                        color: const Color(0xFFEC4899),
                      ),
                      _buildOlxOptionChip(
                        icon: Icons.directions_car,
                        label: 'Distance',
                        value: '~$distanceKm km (~$travelMins m)',
                        color: const Color(0xFFD97706),
                      ),
                      _buildOlxOptionChip(
                        icon: Icons.local_taxi,
                        label: 'Cab Booking',
                        value: 'Uber/Rapido/Ola/EV',
                        color: const Color(0xFF15803D),
                      ),
                      _buildOlxOptionChip(
                        icon: Icons.qr_code_scanner,
                        label: 'Entry Gate',
                        value: 'Encrypted QR Pass',
                        color: const Color(0xFF047857),
                      ),
                      _buildOlxOptionChip(
                        icon: Icons.verified_user,
                        label: 'RSVP Security',
                        value: event.isPublished ? 'Instant Verify' : 'Private Guest List',
                        color: const Color(0xFF3B82F6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── OLX "Description" Section ──
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description & Invitation Note',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppConstants.textDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description.isNotEmpty
                        ? event.description
                        : 'You are cordially invited to celebrate ${event.title} hosted by ${event.hostNames}. Please present your unique digital QR code pass upon arrival for priority check-in.',
                    maxLines: _isDescriptionExpanded ? null : 4,
                    overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppConstants.textDark, height: 1.5),
                  ),
                  if (event.description.length > 140)
                    GestureDetector(
                      onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _isDescriptionExpanded ? 'Read Less ▲' : 'Read More ▼',
                          style: const TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── OLX "Location & Turn-by-Turn GPS Map Card" ──
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.map, color: AppConstants.primaryColor, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Location & Navigation',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppConstants.textDark),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$distanceKm km away',
                          style: const TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(event.venueName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(event.venueAddress, style: const TextStyle(color: AppConstants.textMuted, fontSize: 12)),
                  const SizedBox(height: 14),

                  // Direct Action Buttons for GPS & Rides
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.directions_car, size: 16),
                          label: const Text('Book Cab / Auto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EventRideBookingScreen(event: event)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF0284C7)),
                            foregroundColor: const Color(0xFF0284C7),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.navigation, size: 16),
                          label: const Text('Google Maps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () => _openUrl(gpsUrl),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── OLX "Host / Organizer Profile" Box ──
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppConstants.purpleSurface,
                    child: Text(
                      event.hostNames.isNotEmpty ? event.hostNames[0].toUpperCase() : 'H',
                      style: const TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              event.hostNames,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Color(0xFF0284C7), size: 15),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Celebration Host • Verified by QRouteX',
                          style: TextStyle(color: AppConstants.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: const BorderSide(color: AppConstants.primaryColor),
                    ),
                    onPressed: _shareViaWhatsApp,
                    child: const Text('RSVP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                  ),
                ],
              ),
            ),

            // Space for the sticky bottom bar
            const SizedBox(height: 90),
          ],
        ),
      ),

      // ── OLX SIGNATURE FIXED BOTTOM STICKY ACTION BAR ──
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            // WhatsApp / Chat Button (OLX Chat style)
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: isSmallScreen ? 4 : 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                  foregroundColor: const Color(0xFF10B981),
                ),
                icon: const Icon(Icons.chat, size: 16),
                label: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: _shareViaWhatsApp,
              ),
            ),
            const SizedBox(width: 6),

            // Cab / Auto Booking Button
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: isSmallScreen ? 4 : 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFD97706), width: 1.5),
                  foregroundColor: const Color(0xFFD97706),
                ),
                icon: const Icon(Icons.local_taxi, size: 16),
                label: const Text('Ride', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EventRideBookingScreen(event: event)),
                  );
                },
              ),
            ),
            const SizedBox(width: 6),

            // View Digital QR Card Button (Primary OLX Action)
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: isSmallScreen ? 6 : 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.qr_code, size: 17),
                label: const Text('View QR Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => InvitationCardViewScreen(event: event)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOlxOptionChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppConstants.textMuted,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
