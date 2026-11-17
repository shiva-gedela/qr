import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../models/business_model.dart';
import '../qr/qr_display_screen.dart';

class BusinessDetailScreen extends StatelessWidget {
  final BusinessModel business;

  const BusinessDetailScreen({Key? key, required this.business}) : super(key: key);

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final publicCardUrl = '${AppConstants.baseUrl}/b/${business.slug}/';

    return Scaffold(
      appBar: AppBar(
        title: Text(business.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'Business QR',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QrDisplayScreen(
                    title: business.name,
                    subtitle: 'Business Card QR',
                    qrData: publicCardUrl,
                    qrImageUrl: business.qrImageUrl,
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
            // Header
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: AppConstants.primaryColor,
                      child: Icon(Icons.storefront, size: 36, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(business.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    if (business.tagline.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(business.tagline, textAlign: TextAlign.center, style: const TextStyle(color: AppConstants.textMuted)),
                    ],
                    const SizedBox(height: 12),
                    if (business.isVerified)
                      const Chip(
                        avatar: Icon(Icons.verified, color: Colors.white, size: 16),
                        label: Text('Verified Business', style: TextStyle(color: Colors.white)),
                        backgroundColor: AppConstants.primaryColor,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Actions
            Row(
              children: [
                if (business.phone.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                      onPressed: () => _openUrl('tel:${business.phone}'),
                    ),
                  ),
                if (business.phone.isNotEmpty && business.whatsapp.isNotEmpty) const SizedBox(width: 8),
                if (business.whatsapp.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                      onPressed: () => _openUrl('https://wa.me/${business.whatsapp.replaceAll(RegExp(r'\D'), '')}'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Products & Services
            if (business.services.isNotEmpty) ...[
              const Text('Products & Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...business.services.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.label, color: AppConstants.primaryColor),
                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: s.description.isNotEmpty ? Text(s.description) : null,
                  trailing: s.priceDisplay != null ? Text(s.priceDisplay!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryColor)) : null,
                ),
              )),
              const SizedBox(height: 16),
            ],

            // Display QR Code
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code, color: Colors.white),
              label: const Text('Display Business QR Code', style: TextStyle(color: Colors.white)),
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
                      title: business.name,
                      subtitle: 'Business Card QR',
                      qrData: publicCardUrl,
                      qrImageUrl: business.qrImageUrl,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_browser),
              label: const Text('View Public Digital Card'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _openUrl(publicCardUrl),
            ),
          ],
        ),
      ),
    );
  }
}
