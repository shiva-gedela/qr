import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../models/event_model.dart';
import 'event_portfolio_screen.dart';

enum InvitationTheme {
  royalPurpleGold,
  midnightObsidian,
  roseBloom,
  emeraldPrestige,
}

class InvitationCardViewScreen extends StatefulWidget {
  final EventModel event;
  final String? guestName;

  const InvitationCardViewScreen({
    Key? key,
    required this.event,
    this.guestName,
  }) : super(key: key);

  @override
  State<InvitationCardViewScreen> createState() => _InvitationCardViewScreenState();
}

class _InvitationCardViewScreenState extends State<InvitationCardViewScreen> {
  InvitationTheme _selectedTheme = InvitationTheme.royalPurpleGold;

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareViaWhatsApp() async {
    final message = widget.event.shareMessage;
    final whatsappUrl = "whatsapp://send?text=${Uri.encodeComponent(message)}";
    final webUrl = "https://api.whatsapp.com/send?text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else if (await canLaunchUrl(Uri.parse(webUrl))) {
      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    } else {
      Clipboard.setData(ClipboardData(text: message));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation copied to clipboard! (WhatsApp not detected)')),
        );
      }
    }
  }

  void _downloadPng() {
    final pngUrl = widget.event.downloadPngUrl ??
        (widget.event.qrUuid != null
            ? '${AppConstants.baseUrl}/qr/download/png/${widget.event.qrUuid}/'
            : widget.event.qrImageUrl);
    if (pngUrl != null && pngUrl.isNotEmpty) {
      _openUrl(pngUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading high-res PNG QR Code...')),
      );
    }
  }

  void _downloadPdf() {
    final pdfUrl = widget.event.downloadPdfUrl ??
        (widget.event.qrUuid != null
            ? '${AppConstants.baseUrl}/qr/download/pdf/${widget.event.qrUuid}/'
            : '${AppConstants.baseUrl}/events/e/${widget.event.slug}/');
    _openUrl(pdfUrl);
  }

  void _printCard() {
    final pdfUrl = widget.event.downloadPdfUrl ??
        (widget.event.qrUuid != null
            ? '${AppConstants.baseUrl}/qr/download/pdf/${widget.event.qrUuid}/'
            : '${AppConstants.baseUrl}/events/e/${widget.event.slug}/');
    _openUrl(pdfUrl);
  }

  @override
  Widget build(BuildContext context) {
    final eventUrl = widget.event.targetUrl ?? '${AppConstants.baseUrl}/events/e/${widget.event.slug}/';
    final gpsUrl = widget.event.googleMapsDirectionsUrl ??
        widget.event.googleMapsUrl ??
        'https://maps.google.com/?q=${Uri.encodeComponent("${widget.event.venueName} ${widget.event.venueAddress}")}';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E),
      appBar: AppBar(
        title: const Text('Digital Invitation Card', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: 'Event Portfolio / Gallery',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EventPortfolioScreen(event: widget.event)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Invitation',
            onPressed: _shareViaWhatsApp,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          children: [
            // Theme Selector Chips
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildThemeChip('👑 Royal Gold', InvitationTheme.royalPurpleGold),
                    const SizedBox(width: 8),
                    _buildThemeChip('🌌 Obsidian', InvitationTheme.midnightObsidian),
                    const SizedBox(width: 8),
                    _buildThemeChip('🌸 Rose Bloom', InvitationTheme.roseBloom),
                    const SizedBox(width: 8),
                    _buildThemeChip('🌿 Emerald', InvitationTheme.emeraldPrestige),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ══ The Invitation Card Canvas ══
            _buildInvitationCard(eventUrl),
            const SizedBox(height: 22),

            // ══ Action Toolbar Bar ══
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // GPS Route Direct Launch Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.directions, color: AppConstants.accentColor),
                    label: const Text(
                      'Turn-by-Turn GPS Navigation (Google Maps)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () => _openUrl(gpsUrl),
                  ),
                  const SizedBox(height: 12),

                  // 4 Quick Action Pills
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.qr_code,
                          label: 'Download PNG',
                          color: const Color(0xFF7C4DFF),
                          onTap: _downloadPng,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.picture_as_pdf,
                          label: 'Printable PDF',
                          color: const Color(0xFFEF4444),
                          onTap: _downloadPdf,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.chat,
                          label: 'WhatsApp',
                          color: const Color(0xFF10B981),
                          onTap: _shareViaWhatsApp,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.print,
                          label: 'Print',
                          color: const Color(0xFF2563EB),
                          onTap: _printCard,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeChip(String label, InvitationTheme theme) {
    final isSelected = _selectedTheme == theme;
    return GestureDetector(
      onTap: () => setState(() => _selectedTheme = theme),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.accentColor : Colors.white12,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationCard(String eventUrl) {
    BoxDecoration cardDecoration;
    Color textColor;
    Color subtitleColor;
    Color accentColor;
    Color qrCardBg;

    switch (_selectedTheme) {
      case InvitationTheme.royalPurpleGold:
        cardDecoration = BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B0764), Color(0xFF581C87), Color(0xFF1E1B4B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFFD700), width: 2),
          boxShadow: [
            BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.25), blurRadius: 24),
          ],
        );
        textColor = Colors.white;
        subtitleColor = const Color(0xFFFDE68A);
        accentColor = const Color(0xFFFFB703);
        qrCardBg = Colors.white;
        break;

      case InvitationTheme.midnightObsidian:
        cardDecoration = BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF090D16), Color(0xFF1E1B4B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF00BFA5), width: 1.5),
          boxShadow: [
            BoxShadow(color: const Color(0xFF00BFA5).withOpacity(0.2), blurRadius: 20),
          ],
        );
        textColor = Colors.white;
        subtitleColor = const Color(0xFF94A3B8);
        accentColor = const Color(0xFF00BFA5);
        qrCardBg = Colors.white;
        break;

      case InvitationTheme.roseBloom:
        cardDecoration = BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF831843), Color(0xFFBE185D), Color(0xFF4C0519)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFBCFE8), width: 1.8),
          boxShadow: [
            BoxShadow(color: const Color(0xFFF43F5E).withOpacity(0.3), blurRadius: 24),
          ],
        );
        textColor = Colors.white;
        subtitleColor = const Color(0xFFFCE7F3);
        accentColor = const Color(0xFFFDA4AF);
        qrCardBg = Colors.white;
        break;

      case InvitationTheme.emeraldPrestige:
        cardDecoration = BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF022C22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.8),
          boxShadow: [
            BoxShadow(color: const Color(0xFF10B981).withOpacity(0.25), blurRadius: 24),
          ],
        );
        textColor = Colors.white;
        subtitleColor = const Color(0xFFFEF3C7);
        accentColor = const Color(0xFFFFB703);
        qrCardBg = Colors.white;
        break;
    }

    return Container(
      width: double.infinity,
      decoration: cardDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      child: Column(
        children: [
          // Header Ornament
          Text(
            '✦  ✦  ✦',
            style: TextStyle(color: accentColor, fontSize: 13, letterSpacing: 4),
          ),
          const SizedBox(height: 8),

          // Occasion Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentColor.withOpacity(0.5)),
            ),
            child: Text(
              '${widget.event.eventTypeIcon} ${widget.event.eventTypeName.toUpperCase()}',
              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 14),

          // Guest Greeting (If applicable)
          if (widget.guestName != null && widget.guestName!.isNotEmpty) ...[
            Text(
              'Specially Invited Guest:',
              style: TextStyle(color: subtitleColor.withOpacity(0.8), fontSize: 11, fontStyle: FontStyle.italic),
            ),
            Text(
              widget.guestName!,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
          ],

          // Event Title
          Text(
            widget.event.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Host Names
          Text(
            'Hosted by ${widget.event.hostNames}',
            textAlign: TextAlign.center,
            style: TextStyle(color: subtitleColor, fontSize: 13, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 18),

          // Date & Time Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_month, color: accentColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  widget.event.eventDate,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (widget.event.eventTime != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.access_time, color: accentColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    widget.event.eventTime!,
                    style: TextStyle(color: textColor, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Venue & GPS Location
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, color: accentColor, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.event.venueName,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          if (widget.event.venueAddress.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                widget.event.venueAddress,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: subtitleColor.withOpacity(0.85), fontSize: 11),
              ),
            ),
          const SizedBox(height: 20),

          // ── Unique QR Code Container ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: qrCardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                QrImageView(
                  data: eventUrl,
                  version: QrVersions.auto,
                  size: 160.0,
                  backgroundColor: qrCardBg,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF3B0764),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.camera_alt, size: 13, color: AppConstants.primaryColor),
                    SizedBox(width: 4),
                    Text(
                      'Scan to Open & Navigate GPS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppConstants.textDark),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Footer branding
          Text(
            'Powered by QRouteX • qroutex.com',
            style: TextStyle(color: subtitleColor.withOpacity(0.65), fontSize: 10, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
