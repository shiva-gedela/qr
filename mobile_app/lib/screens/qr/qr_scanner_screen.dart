import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../constants.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';

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
  String? _loadError;
  bool _isLoadingEvents = true;
  bool _isProcessing = false;
  bool _isSyncing = false;
  bool _isRefreshingSummary = false;
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
    setState(() {
      _isLoadingEvents = true;
      _loadError = null;
    });
    try {
      final events = await ApiService.getCheckInEvents();
      if (!mounted) return;
      setState(() {
        _events = events;
        _selectedEvent = events.isNotEmpty ? events.first : null;
        _isLoadingEvents = false;
      });
      if (_selectedEvent != null) await _refreshSummary();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoadingEvents = false;
      });
    }
  }

  Future<void> _loadPendingCount() async {
    final count = await ApiService.pendingCheckInCount();
    if (mounted) setState(() => _pendingCount = count);
  }

  Future<void> _refreshSummary() async {
    final event = _selectedEvent;
    if (event == null || _isRefreshingSummary) return;
    _isRefreshingSummary = true;
    try {
      final summary = await ApiService.getCheckInSummary(event.id);
      if (mounted) {
        setState(() {
          _summary = summary;
          _summaryError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _summary = {};
          _summaryError = error.toString();
        });
      }
    } finally {
      _isRefreshingSummary = false;
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

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _selectedEvent == null || capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);
    await _controller.stop();
    final token = _extractToken(code);
    Map<String, dynamic> result;
    if (token == null) {
      result = {'result': 'rejected', 'reason': 'invalid_qr'};
    } else {
      try {
        result = await ApiService.verifyInvitation(_selectedEvent!.id, token);
      } on ApiConnectionException {
        await ApiService.queuePendingCheckIn(_selectedEvent!.id, token);
        result = {'result': 'pending', 'reason': 'offline'};
        await _loadPendingCount();
      } catch (error) {
        result = {'result': 'error', 'reason': error.toString()};
      }
    }

    if (!mounted) return;
    final status = result['result'] as String? ?? 'error';
    final Color color;
    if (status == 'approved') {
      color = AppConstants.successColor;
    } else if (status == 'already_checked_in' || status == 'pending') {
      color = AppConstants.accentColor;
    } else {
      color = AppConstants.dangerColor;
    }
    final title = switch (status) {
      'approved' => 'Entry approved',
      'already_checked_in' => 'Already checked in',
      'pending' => 'Saved for sync — not approved',
      'rejected' => 'Entry rejected',
      _ => 'Could not verify entry',
    };

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final guest = result['guest'] as Map<String, dynamic>?;
        final checkedInAt = result['checked_in_at']?.toString();
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                status == 'approved'
                    ? Icons.check_circle
                    : status == 'already_checked_in'
                        ? Icons.info
                        : Icons.cancel,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (guest != null) ...[
                Text('Guest: ${guest['name'] ?? ''}'),
                Text('Admits: ${guest['guest_count'] ?? 1}'),
                Text('Type: ${guest['invitation_type'] ?? 'general'}'),
              ],
              if (checkedInAt != null) Text('Check-in time: $checkedInAt'),
              if (result['reason'] != null)
                Text('Reason: ${result['reason']}', style: const TextStyle(color: AppConstants.textMuted)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue scanning'),
            ),
          ],
        );
      },
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      await _refreshSummary();
      await _controller.start();
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
      appBar: AppBar(
        title: const Text('Guest entry scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Toggle flashlight',
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            tooltip: 'Switch camera',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: _isLoadingEvents
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_loadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadEvents, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _events.isEmpty
                  ? const Center(child: Text('No events are assigned to this account.'))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Column(
                            children: [
                              DropdownButtonFormField<EventModel>(
                                value: _selectedEvent,
                                decoration: const InputDecoration(labelText: 'Select event'),
                                items: _events.map((event) {
                                  return DropdownMenuItem(value: event, child: Text(event.title, overflow: TextOverflow.ellipsis));
                                }).toList(),
                                onChanged: (event) async {
                                  setState(() => _selectedEvent = event);
                                  await _refreshSummary();
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _summaryError == null
                                          ? 'Checked in: ${_summary['checked_in_guests'] ?? 0}'
                                          : 'Live count unavailable',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (_pendingCount > 0)
                                    TextButton.icon(
                                      onPressed: _isSyncing ? null : _syncPending,
                                      icon: _isSyncing
                                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                          : const Icon(Icons.sync),
                                      label: Text('Sync $_pendingCount pending'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              MobileScanner(controller: _controller, onDetect: _onDetect),
                              Center(
                                child: Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppConstants.primaryColor, width: 3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                              const Positioned(
                                bottom: 24,
                                left: 20,
                                right: 20,
                                child: Center(
                                  child: Text(
                                    'Scan a guest invitation QR. Offline scans stay pending until the server verifies them.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
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
