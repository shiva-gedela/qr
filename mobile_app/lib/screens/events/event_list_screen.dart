import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import 'event_detail_screen.dart';
import 'event_create_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({Key? key}) : super(key: key);

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  late Future<List<EventModel>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      _eventsFuture = ApiService.getEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _loadEvents(),
        child: FutureBuilder<List<EventModel>>(
          future: _eventsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: AppConstants.textMuted),
                      const SizedBox(height: 12),
                      Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadEvents, child: const Text('Retry')),
                    ],
                  ),
                ),
              );
            }

            final events = snapshot.data ?? [];
            if (events.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 64, color: AppConstants.textMuted),
                    const SizedBox(height: 16),
                    const Text('No events created yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Create an event to generate your first custom invitation QR code.'),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Create Event'),
                      onPressed: () async {
                        final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EventCreateScreen()));
                        if (created == true) _loadEvents();
                      },
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final ev = events[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: ev)));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  ev.eventType.toUpperCase(),
                                  style: const TextStyle(color: AppConstants.primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Icon(
                                ev.isPublished ? Icons.check_circle : Icons.edit_note,
                                color: ev.isPublished ? AppConstants.successColor : AppConstants.textMuted,
                                size: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(ev.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Hosts: ${ev.hostNames}', style: const TextStyle(color: AppConstants.textMuted, fontSize: 13)),
                          const Divider(height: 20),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 16, color: AppConstants.primaryColor),
                              const SizedBox(width: 4),
                              Text(ev.eventDate, style: const TextStyle(fontSize: 12)),
                              const Spacer(),
                              const Icon(Icons.location_on, size: 16, color: AppConstants.dangerColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  ev.venueName,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'createEventFab',
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Event', style: TextStyle(color: Colors.white)),
        onPressed: () async {
          final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EventCreateScreen()));
          if (created == true) _loadEvents();
        },
      ),
    );
  }
}
