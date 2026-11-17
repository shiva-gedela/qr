import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../models/subscription_model.dart';
import '../../services/api_service.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({Key? key}) : super(key: key);

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  late Future<List<SubscriptionPlanModel>> _plansFuture;

  @override
  void initState() {
    super.initState();
    _plansFuture = ApiService.getSubscriptionPlans();
  }

  void _openCheckout(String planCode) async {
    final url = '${AppConstants.baseUrl}/subscriptions/checkout/$planCode/';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<SubscriptionPlanModel>>(
        future: _plansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final plans = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              final isWedding = plan.code == 'wedding_package';

              return Card(
                elevation: isWedding ? 4 : 1,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isWedding ? const BorderSide(color: AppConstants.primaryColor, width: 2) : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(plan.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          if (plan.badge.isNotEmpty)
                            Chip(
                              label: Text(plan.badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                              backgroundColor: isWedding ? AppConstants.primaryColor : Colors.orange,
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(plan.description, style: const TextStyle(color: AppConstants.textMuted, fontSize: 13)),
                      const SizedBox(height: 12),
                      Text(
                        plan.priceDisplay,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                      ),
                      const Divider(height: 24),
                      Text('• Up to ${plan.maxEvents} Event${plan.maxEvents > 1 ? "s" : ""}'),
                      Text('• ${plan.maxStorageMb} MB Media Storage'),
                      Text('• ${plan.customQrAllowed ? "Custom QR Colors & Logo" : "Standard QR Code"}'),
                      Text('• ${plan.guestUploadAllowed ? "Guest Photo Uploads & Moderation" : "Host Only Uploads"}'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isWedding ? AppConstants.primaryColor : Colors.grey.shade800,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _openCheckout(plan.code),
                          child: Text(plan.code == 'free' ? 'Current Plan' : 'Select Plan'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
