import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import '../events/event_ride_booking_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  List<EventModel> _events = [];
  EventModel? _selectedEvent;
  Map<String, dynamic> _summary = {};
  String? _summaryError;
  bool _isProcessing = false;
  bool _isSyncing = false;
  bool _isTorchOn = false;
  Timer? _summaryTimer;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _loadPendingCount();
    _summaryTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refreshSummary());
  }

  Future<void> _loadEvents() async {
    try {
      final events = await ApiService.getCheckInEvents();
      if (!mounted) return;
      setState(() {
        _events = events;
        if (events.isNotEmpty && _selectedEvent == null) {
          _selectedEvent = events.first;
        }
      });
      if (_selectedEvent != null) await _refreshSummary();
    } catch (_) {
      // Camera continues running smoothly
    }
  }

  Future<void> _loadPendingCount() async {
    final count = await ApiService.pendingCheckInCount();
    if (!mounted) return;
    setState(() => _pendingCount = count);
  }

  Future<void> _refreshSummary() async {
    if (_selectedEvent == null) return;
    try {
      final summary = await ApiService.getCheckInSummary(_selectedEvent!.id);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _summaryError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _summaryError = error.toString());
    }
  }

  Future<void> _syncPending() async {
    setState(() => _isSyncing = true);
    final results = await ApiService.syncPendingCheckIns();
    await _loadPendingCount();
    if (!mounted) return;
    setState(() => _isSyncing = false);
    final completed = results.where((item) => item['result'] != null).toList();
    final approved = completed.where((item) => item['result']['result'] == 'approved').length;
    final unresolved = results.length - completed.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Processed ${completed.length} scan(s); $approved approved; $unresolved still pending.')),
    );
    await _refreshSummary();
  }

  String? _extractToken(String raw) {
    final value = raw.trim();
    final uri = Uri.tryParse(value);
    final candidates = <String>[value];
    if (uri != null) candidates.addAll(uri.pathSegments.reversed);
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    for (final candidate in candidates) {
      if (uuidPattern.hasMatch(candidate)) return candidate;
    }
    return null;
  }

  Future<void> _scanFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isProcessing = true);
      final BarcodeCapture? capture = await _controller.analyzeImage(image.path);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (capture != null && capture.barcodes.isNotEmpty) {
        await _onDetect(capture);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No QR code detected in the selected image. Please try a clearer photo or screenshot.'),
            backgroundColor: AppConstants.warningColor,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not scan image: $e'),
          backgroundColor: AppConstants.dangerColor,
        ),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) return;

    setState(() => _isProcessing = true);
    await _controller.stop();

    final token = _extractToken(code);

    // If an event is selected and it looks like a check-in token, process check-in
    if (_selectedEvent != null && token != null) {
      Map<String, dynamic> result;
      try {
        result = await ApiService.verifyInvitation(_selectedEvent!.id, token);
      } on ApiConnectionException {
        await ApiService.queuePendingCheckIn(_selectedEvent!.id, token);
        result = {'result': 'pending', 'reason': 'offline'};
        await _loadPendingCount();
      } catch (error) {
        result = {'result': 'error', 'reason': error.toString()};
      }

      if (!mounted) return;
      final status = result['result'] as String? ?? 'error';
      final Color color = status == 'approved'
          ? AppConstants.successColor
          : (status == 'already_checked_in' || status == 'pending')
              ? AppConstants.accentColor
              : AppConstants.dangerColor;

      final title = switch (status) {
        'approved' => 'Entry Approved',
        'already_checked_in' => 'Already Checked In',
        'pending' => 'Saved for Sync (Offline)',
        'rejected' => 'Entry Rejected',
        _ => 'Could Not Verify Entry',
      };

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final guest = result['guest'] as Map<String, dynamic>?;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  status == 'approved' ? Icons.check_circle : Icons.info,
                  color: color,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (guest != null) ...[
                  Text('Guest: ${guest['name'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Passes: ${guest['guest_count'] ?? 1} • Type: ${(guest['invitation_type'] ?? 'Standard').toString().toUpperCase()}'),
                ],
                const SizedBox(height: 8),
                Text('Scanned: $code', style: const TextStyle(fontSize: 12, color: AppConstants.textMuted)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _isProcessing = false);
                  _controller.start();
                },
                child: const Text('Scan Next', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
      return;
    }

    // Generic QR Scan / URL / GPS Route Sheet (PhonePe Style)
    if (!mounted) return;
    final isUrl = code.startsWith('http://') || code.startsWith('https://');
    final isGps = code.contains('maps.google.com') || code.contains('goo.gl/maps') || code.startsWith('geo:');

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppConstants.purpleSurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: AppConstants.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGps ? '📍 GPS Route Location' : (isUrl ? '🌐 Event Link Scanned' : '📄 Scanned QR Code'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const Text('QRouteX Universal Scanner', style: TextStyle(fontSize: 12, color: AppConstants.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppConstants.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  code,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 20),
              if (isGps || isUrl) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(isGps ? Icons.directions : Icons.open_in_browser),
                  label: Text(
                    isGps ? 'Start GPS Navigation (Google Maps)' : 'Open Event Invitation',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: () {
                    _openUrl(code);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.directions_car),
                  label: const Text(
                    'Book Ride (Uber / Rapido / Ola / Green SM)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventRideBookingScreen(
                          destinationName: isGps ? 'Scanned GPS Destination' : 'Scanned Event Destination',
                          destinationAddress: code,
                          customMapsUrl: isGps ? code : null,
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.copy),
                label: const Text('Copy to Clipboard'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard!')),
                  );
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Scan Another QR', style: TextStyle(color: AppConstants.textMuted)),
              ),
            ],
          ),
        );
      },
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      _controller.start();
    }
  }

  @override
  void dispose() {
    _summaryTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Any QR Code', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: 'Scan QR from Gallery',
            onPressed: _scanFromGallery,
          ),
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            tooltip: 'Toggle Flash',
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            tooltip: 'Switch Camera',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full Screen Camera Feed
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // PhonePe-Style Glowing Reticle Overlay
          Center(
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                border: Border.all(color: AppConstants.accentColor, width: 3),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // Top Event Selector Bar (If host wants check-in mode)
          if (_events.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.how_to_reg, color: AppConstants.accentColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<EventModel>(
                          value: _selectedEvent,
                          dropdownColor: const Color(0xFF1E1B4B),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          isExpanded: true,
                          items: _events.map((e) {
                            return DropdownMenuItem(
                              value: e,
                              child: Text('${e.eventTypeIcon} ${e.title}', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (e) {
                            setState(() => _selectedEvent = e);
                            _refreshSummary();
                          },
                        ),
                      ),
                    ),
                    if (_pendingCount > 0)
                      TextButton(
                        onPressed: _isSyncing ? null : _syncPending,
                        child: Text('Sync ($_pendingCount)', style: const TextStyle(color: AppConstants.accentColor, fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),

          // Bottom Controls & Gallery Scan Button
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppConstants.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 6,
                  ),
                  icon: const Icon(Icons.photo_library, color: AppConstants.primaryColor),
                  label: const Text(
                    'Scan QR from Gallery or Screenshot',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: _scanFromGallery,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Point camera at any Event QR, GPS code, or choose from Gallery',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
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
