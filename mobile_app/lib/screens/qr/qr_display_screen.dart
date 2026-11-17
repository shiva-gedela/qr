import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../constants.dart';

class QrDisplayScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String qrData;
  final String? qrImageUrl;

  const QrDisplayScreen({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.qrData,
    this.qrImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display QR Code')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: AppConstants.textMuted, fontSize: 13)),
                      const SizedBox(height: 24),

                      // Generated QR Image
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 240.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        qrData,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Let guests or customers scan this code with their smartphone camera.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppConstants.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
