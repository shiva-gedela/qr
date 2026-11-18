import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../models/event_model.dart';
import 'invitation_card_view_screen.dart';
import 'event_portfolio_screen.dart';
import 'event_ride_booking_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareViaWhatsApp(BuildContext context) async {
    final message = event.shareMessage;
    final whatsappUrl = "whatsapp://send?text=${Uri.encodeComponent(message)}";
    final webUrl = "https://api.whatsapp.com/send?text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else if (await canLaunchUrl(Uri.parse(webUrl))) {
      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    } else {
      Clipboard.setData(ClipboardData(text: message));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventUrl = event.targetUrl ?? '${AppConstants.baseUrl}/events/e/${event.slug}/';
    final gpsUrl = event.googleMapsDirectionsUrl ??
        event.googleMapsUrl ??
        'https://maps.google.com/?q=${Uri.encodeComponent("${event.venueName} ${event.venueAddress}")}';

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () => _shareViaWhatsApp(context),
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: 'Event Portfolio',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EventPortfolioScreen(event: event)),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero Banner Card ──
            Container(
              decoration: BoxDecoration(
                gradient: AppConstants.passvantaCardGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppConstants.primaryColor.withOpacity(0.2), blurRadius: 16),
                ],
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Text(event.eventTypeIcon, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hosted with love by ${event.hostNames}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppConstants.accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppConstants.accentColor),
                    ),
                    child: Text(
                      'STATUS: ${event.statusText.toUpperCase()}',
                      style: const TextStyle(color: AppConstants.accentColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Primary Actions: View Invitation Card & Event Portfolio ──
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              icon: const Icon(Icons.style, color: AppConstants.accentColor),
              label: const Text(
                'View Digital Invitation Card (4 Themes)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => InvitationCardViewScreen(event: event)),
                );
              },
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.photo_library),
              label: const Text(
                'Event Portfolio & Moments Gallery',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EventPortfolioScreen(event: event)),
                );
              },
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.chat),
              label: const Text(
                'Share Invitation via WhatsApp',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: () => _shareViaWhatsApp(context),
            ),
            const SizedBox(height: 18),

            // ── Venue & GPS Navigation Card ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.directions, color: AppConstants.primaryColor),
                      SizedBox(width: 8),
                      Text('Venue & Driving Navigation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(event.venueName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(event.venueAddress, style: const TextStyle(color: AppConstants.textMuted, fontSize: 12)),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(Icons.directions_car, color: Colors.white, size: 20),
                    label: const Text(
                      'Compare Rides & Book (Uber, Rapido, Ola, Green SM)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventRideBookingScreen(event: event),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppConstants.primaryColor),
                      foregroundColor: AppConstants.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.navigation, color: AppConstants.primaryColor, size: 18),
                    label: const Text('Start GPS Turn-by-Turn in Google Maps', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _openUrl(gpsUrl),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Date & Time Card ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppConstants.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Date: ${event.eventDate}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (event.eventTime != null) ...[
                        const SizedBox(width: 8),
                        Text('• ${event.eventTime}', style: const TextStyle(color: AppConstants.textMuted, fontSize: 13)),
                      ],
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Guest Capacity: ${event.capacity} Passes', style: const TextStyle(fontSize: 13)),
                      Text('Confirmed: ${event.guestCount}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Open Public Mini-Website
            OutlinedButton.icon(
              icon: const Icon(Icons.public),
              label: const Text('Open Public Web Invitation'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _openUrl(eventUrl),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
