import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../models/business_model.dart';
import '../qr/qr_display_screen.dart';

class BusinessDetailScreen extends StatefulWidget {
  final BusinessModel business;

  const BusinessDetailScreen({Key? key, required this.business}) : super(key: key);

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  bool _isFavorite = false;
  bool _isDescriptionExpanded = false;

  void _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareVendor() async {
    final b = widget.business;
    final publicCardUrl = '${AppConstants.baseUrl}/b/${b.slug}/';
    final message = "Check out *${b.name}* (${b.categoryTitle}) on QRouteX!\n\n"
        "📍 ${b.city.isNotEmpty ? b.city : 'Bengaluru'}, ${b.state.isNotEmpty ? b.state : 'Karnataka'}\n"
        "📞 Contact: ${b.phone}\n"
        "🔗 Digital Profile: $publicCardUrl\n\n"
        "Discover smart event vendors on QRouteX: https://qroutex.com";

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
        const SnackBar(content: Text('Vendor details copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.business;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final publicCardUrl = '${AppConstants.baseUrl}/b/${b.slug}/';

    // Derive starting price if available
    String startingPrice = 'Contact for Pricing';
    if (b.services.isNotEmpty) {
      final prices = b.services
          .map((s) => s.priceDisplay)
          .where((p) => p != null && p.isNotEmpty)
          .toList();
      if (prices.isNotEmpty) {
        startingPrice = 'Starting ${prices.first}';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      // ── Custom OLX Header ──
      appBar: AppBar(
        title: Text(
          b.name,
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
            icon: const Icon(Icons.share),
            tooltip: 'Share Vendor',
            onPressed: _shareVendor,
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'Business QR',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QrDisplayScreen(
                    title: b.name,
                    subtitle: 'Business Card QR',
                    qrData: publicCardUrl,
                    qrImageUrl: b.qrImageUrl,
                  ),
                ),
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
            // ── OLX Hero Cover Banner ──
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: isSmallScreen ? 180 : 210,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E1065), Color(0xFF4A148C), Color(0xFF5F259F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    image: b.coverImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(b.coverImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: b.coverImageUrl == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(b.categoryEmoji, style: const TextStyle(fontSize: 52)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  b.categoryTitle.toUpperCase(),
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

                // Top Status Badge (Verified Pro Seller)
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
                          'VERIFIED PRO VENDOR',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),

                // Photo Counter
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
                          '1 / ${b.services.length + 1}',
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
                  // Prominent Starting Price Tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          startingPrice,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 19 : 23,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textDark,
                          ),
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
                          b.isActive ? 'ACTIVE PROVIDER' : 'STANDBY',
                          style: const TextStyle(
                            color: Color(0xFF047857),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Business Name + Verified Icon
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          b.name,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 17 : 19,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textDark,
                          ),
                        ),
                      ),
                      if (b.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: Color(0xFF0284C7), size: 20),
                      ],
                    ],
                  ),
                  if (b.tagline.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      b.tagline,
                      style: const TextStyle(color: AppConstants.textMuted, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 10),

                  // Location Footer Row
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppConstants.primaryColor, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${b.address.isNotEmpty ? "${b.address}, " : ""}${b.city.isNotEmpty ? b.city : "Bengaluru"}, ${b.state.isNotEmpty ? b.state : "Karnataka"}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppConstants.textDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(Icons.timer_outlined, color: Colors.grey, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Fast Response • High Quality Event Partner',
                        style: TextStyle(fontSize: 11, color: AppConstants.textMuted),
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
                        icon: Icons.category,
                        label: 'Category',
                        value: b.categoryTitle,
                        color: const Color(0xFF7C4DFF),
                      ),
                      _buildOlxOptionChip(
                        icon: Icons.location_city,
                        label: 'City',
                        value: b.city.isNotEmpty ? b.city : 'Bengaluru',
                        color: const Color(0xFF0284C7),
                      ),
                      _buildOlxOptionChip(
                        icon: Icons.verified_user,
                        label: 'Verification',
                        value: b.isVerified ? 'Verified Pro' : 'Direct Host',
                        color: const Color(0xFF10B981),
                      ),
                      _buildOlxOptionChip(
                        icon: Icons.speed,
                        label: 'Response',
                        value: 'Within 1 Hour',
                        color: const Color(0xFFF59E0B),
                      ),
                      _buildOlxOptionChip(
                        icon: Icons.phone,
                        label: 'Phone Contact',
                        value: b.phone.isNotEmpty ? b.phone : 'Available',
                        color: const Color(0xFF6366F1),
                      ),
                      _buildOlxOptionChip(
                        icon: Icons.chat,
                        label: 'WhatsApp',
                        value: b.whatsapp.isNotEmpty ? 'Active Chat' : 'On Request',
                        color: const Color(0xFF10B981),
                      ),
                      _buildOlxOptionChip(
                        icon: Icons.inventory_2,
                        label: 'Packages',
                        value: '${b.services.length} Listed',
                        color: const Color(0xFFEC4899),
                      ),
                      _buildOlxOptionChip(
                        icon: Icons.qr_code,
                        label: 'Digital Card',
                        value: 'Smart QR Pass',
                        color: const Color(0xFF047857),
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
                    'Description & Services',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppConstants.textDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    b.description.isNotEmpty
                        ? b.description
                        : '${b.name} is a premier ${b.categoryTitle.toLowerCase()} vendor listed on QRouteX. Delivering top-tier quality, punctual service, and customized packages for weddings, birthdays, corporate celebrations, and festive parties.',
                    maxLines: _isDescriptionExpanded ? null : 4,
                    overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppConstants.textDark, height: 1.5),
                  ),
                  if (b.description.length > 130)
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

            // ── Products, Packages & Menu Catalog ──
            if (b.services.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Packages & Catalog',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppConstants.textDark),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppConstants.purpleSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${b.services.length} Options',
                            style: const TextStyle(
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...b.services.map((s) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.star, color: AppConstants.primaryColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppConstants.textDark),
                                    ),
                                    if (s.description.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        s.description,
                                        style: const TextStyle(fontSize: 12, color: AppConstants.textMuted),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (s.priceDisplay != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    s.priceDisplay!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFF047857),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            if (b.services.isNotEmpty) const SizedBox(height: 10),

            // ── OLX "Seller / Vendor Location & Trust" Box ──
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
                          Icon(Icons.location_on, color: AppConstants.primaryColor, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Vendor Location',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppConstants.textDark),
                          ),
                        ],
                      ),
                      if (b.mapsUrl != null && b.mapsUrl!.isNotEmpty)
                        TextButton.icon(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          icon: const Icon(Icons.directions, size: 16, color: AppConstants.primaryColor),
                          label: const Text('Open Map', style: TextStyle(color: AppConstants.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => _openUrl(b.mapsUrl!),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${b.address.isNotEmpty ? "${b.address}\n" : ""}${b.city.isNotEmpty ? b.city : "Bengaluru"}, ${b.state.isNotEmpty ? b.state : "Karnataka"}',
                    style: const TextStyle(fontSize: 13, color: AppConstants.textDark, height: 1.4),
                  ),
                  const SizedBox(height: 10),

                  // Trust tip box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.security, color: Color(0xFF2563EB), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Verified QRouteX Partner. Connect directly without broker commission.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Space for sticky bottom bar
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
            // Call Button
            if (b.phone.isNotEmpty) ...[
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: isSmallScreen ? 4 : 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                    foregroundColor: const Color(0xFF0284C7),
                  ),
                  icon: const Icon(Icons.call, size: 16),
                  label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () => _openUrl('tel:${b.phone}'),
                ),
              ),
              const SizedBox(width: 6),
            ],

            // WhatsApp Chat Button (OLX Chat style)
            if (b.whatsapp.isNotEmpty) ...[
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
                  onPressed: () => _openUrl('https://wa.me/${b.whatsapp.replaceAll(RegExp(r'\D'), '')}'),
                ),
              ),
              const SizedBox(width: 6),
            ],

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
                label: const Text('Business QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QrDisplayScreen(
                        title: b.name,
                        subtitle: 'Business Card QR',
                        qrData: publicCardUrl,
                        qrImageUrl: b.qrImageUrl,
                      ),
                    ),
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
