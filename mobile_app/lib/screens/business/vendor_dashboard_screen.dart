import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../models/business_model.dart';
import '../../services/api_service.dart';
import 'vendor_add_screen.dart';

class VendorDashboardScreen extends StatefulWidget {
  final BusinessModel? business;

  const VendorDashboardScreen({Key? key, this.business}) : super(key: key);

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  BusinessModel? _currentBusiness;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _inquiries = [
    {
      'id': 'INQ-101',
      'client': 'Aishwarya Sharma',
      'service': 'Full Day Photography & Cinematic Reel',
      'date': 'Dec 15, 2026',
      'guests': '350 Guests',
      'status': 'pending',
      'phone': '+91 98765 11223',
    },
    {
      'id': 'INQ-102',
      'client': 'Rajesh Verma',
      'service': 'Royal North & South Indian Buffet (250 plates)',
      'date': 'Jan 05, 2027',
      'guests': '250 Guests',
      'status': 'accepted',
      'phone': '+91 98440 22334',
    },
    {
      'id': 'INQ-103',
      'client': 'Neha Patel',
      'service': 'Floral Mandap & Stage LED Lighting',
      'date': 'Dec 22, 2026',
      'guests': '500 Guests',
      'status': 'pending',
      'phone': '+91 97312 99887',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    if (widget.business != null) {
      setState(() {
        _currentBusiness = widget.business;
        _isLoading = false;
      });
      return;
    }

    try {
      final list = await ApiService.getBusinesses();
      if (!mounted) return;
      setState(() {
        _currentBusiness = list.isNotEmpty ? list.first : null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _openCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final b = _currentBusiness;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Vendor Partner Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: AppConstants.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Vendor Business Header ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(color: AppConstants.primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(b?.categoryEmoji ?? '🏬', style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    b?.name ?? 'QRouteX Vendor',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppConstants.accentColor, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('PRO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 9)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(b?.categoryTitle ?? 'Event Partner', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                            const SizedBox(height: 2),
                            Text('📍 ${b?.city ?? "Bengaluru"} • Active Storefront', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Analytics / KPI Stats Row
                  Row(
                    children: [
                      _buildMetricTile('Profile Views', '1,420', Icons.remove_red_eye),
                      _buildMetricTile('Bookings', '28', Icons.calendar_today),
                      _buildMetricTile('Est. Revenue', '₹84,500', Icons.currency_rupee),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Quick Partner Action Row ──
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Service / Menu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorAddScreen()));
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: AppConstants.primaryColor),
                    ),
                    icon: const Icon(Icons.share, size: 18, color: AppConstants.primaryColor),
                    label: const Text('Share Storefront', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Storefront link copied to clipboard!')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Booking Requests & Client Inquiries ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Client Inquiries & Requests',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.textDark),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                  child: Text('${_inquiries.length} Inquiries', style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ..._inquiries.map((inq) => _buildInquiryCard(inq)),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppConstants.accentColor, size: 18),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildInquiryCard(Map<String, dynamic> inq) {
    final isPending = inq['status'] == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(inq['client'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPending ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPending ? 'PENDING' : 'ACCEPTED',
                  style: TextStyle(
                    color: isPending ? const Color(0xFFD97706) : const Color(0xFF047857),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(inq['service'], style: const TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(inq['date'], style: const TextStyle(fontSize: 11, color: AppConstants.textMuted)),
              const SizedBox(width: 12),
              const Icon(Icons.people, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(inq['guests'], style: const TextStyle(fontSize: 11, color: AppConstants.textMuted)),
            ],
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.call, color: Color(0xFF0284C7), size: 20),
                tooltip: 'Call Client',
                onPressed: () => _openCall(inq['phone']),
              ),
              IconButton(
                icon: const Icon(Icons.chat, color: Color(0xFF10B981), size: 20),
                tooltip: 'WhatsApp Client',
                onPressed: () => _openWhatsApp(inq['phone']),
              ),
              const SizedBox(width: 6),
              if (isPending) ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.dangerColor,
                    side: const BorderSide(color: AppConstants.dangerColor),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () {
                    setState(() => inq['status'] = 'declined');
                  },
                  child: const Text('Decline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  ),
                  onPressed: () {
                    setState(() => inq['status'] = 'accepted');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking accepted! Client has been notified.')),
                    );
                  },
                  child: const Text('Accept', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
