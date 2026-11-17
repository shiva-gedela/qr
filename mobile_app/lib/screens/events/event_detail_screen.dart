import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../models/event_model.dart';
import '../qr/qr_display_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventUrl = '${AppConstants.baseUrl}/events/e/${event.slug}/';

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'View QR Code',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QrDisplayScreen(
                    title: event.title,
                    subtitle: 'Event Invitation QR',
                    qrData: eventUrl,
                    qrImageUrl: event.qrImageUrl,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.celebration, size: 54, color: AppConstants.primaryColor),
                    const SizedBox(height: 8),
                    Text(
                      event.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Hosted by ${event.hostNames}', style: const TextStyle(color: AppConstants.textMuted)),
                    const SizedBox(height: 16),
                    Chip(
                      label: Text(
                        event.isPublished ? 'Published & Live' : 'Draft Invitation',
                        style: TextStyle(color: event.isPublished ? Colors.green.shade800 : Colors.grey.shade800),
                      ),
                      backgroundColor: event.isPublished ? Colors.green.shade100 : Colors.grey.shade200,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date & Venue Details
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today, color: AppConstants.primaryColor),
                      title: const Text('Date & Time'),
                      subtitle: Text('${event.eventDate} ${event.eventTime ?? ""}'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.location_on, color: AppConstants.dangerColor),
                      title: Text(event.venueName),
                      subtitle: Text(event.venueAddress),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code, color: Colors.white),
              label: const Text('Display Invitation QR Code', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QrDisplayScreen(
                      title: event.title,
                      subtitle: 'Event Invitation QR',
                      qrData: eventUrl,
                      qrImageUrl: event.qrImageUrl,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open Event Mini-Website'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _openUrl(eventUrl),
            ),

            if (event.googleMapsUrl != null && event.googleMapsUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.directions, color: AppConstants.dangerColor),
                label: const Text('Get Venue Directions (Google Maps)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _openUrl(event.googleMapsUrl!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
