class EventModel {
  final int id;
  final String title;
  final String slug;
  final String eventType;
  final String hostNames;
  final String description;
  final String eventDate;
  final String? eventTime;
  final String venueName;
  final String venueAddress;
  final String? googleMapsUrl;
  final String? googleMapsDirectionsUrl;
  final String? instagramUrl;
  final String? youtubeUrl;
  final String? eventHashtag;
  final String? dressCode;
  final String? coverImageUrl;
  final bool isPublished;
  final String? qrImageUrl;
  final String? targetUrl;
  final int capacity;
  final int guestCount;
  final String? organizerName;
  final String? organizerContact;
  final String? qrUuid;
  final String? downloadPngUrl;
  final String? downloadPdfUrl;
  final List<Map<String, dynamic>> photos;

  EventModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.eventType,
    required this.hostNames,
    required this.description,
    required this.eventDate,
    this.eventTime,
    required this.venueName,
    required this.venueAddress,
    this.googleMapsUrl,
    this.googleMapsDirectionsUrl,
    this.instagramUrl,
    this.youtubeUrl,
    this.eventHashtag,
    this.dressCode,
    this.coverImageUrl,
    required this.isPublished,
    this.qrImageUrl,
    this.targetUrl,
    this.capacity = 100,
    this.guestCount = 0,
    this.organizerName,
    this.organizerContact,
    this.qrUuid,
    this.downloadPngUrl,
    this.downloadPdfUrl,
    this.photos = const [],
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    String? qrImg;
    String? target;
    String? qrId;
    String? pngUrl;
    String? pdfUrl;

    if (json['qr_code'] != null && json['qr_code'] is Map) {
      final qr = json['qr_code'];
      qrImg = qr['image_url'] ?? qr['qr_image_url'] ?? qr['qr_image'];
      target = qr['target_url'];
      qrId = qr['uuid']?.toString();
      pngUrl = qr['download_png_url'];
      pdfUrl = qr['download_pdf_url'];
    }

    final rawPhotos = json['photos'];
    List<Map<String, dynamic>> photoList = [];
    if (rawPhotos is List) {
      photoList = rawPhotos.map((p) => Map<String, dynamic>.from(p is Map ? p : {})).toList();
    }

    return EventModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      eventType: json['event_type'] ?? 'other',
      hostNames: json['host_names'] ?? '',
      description: json['description'] ?? '',
      eventDate: json['event_date'] ?? '',
      eventTime: json['event_time'],
      venueName: json['venue_name'] ?? '',
      venueAddress: json['venue_address'] ?? '',
      googleMapsUrl: json['maps_url'] ?? json['google_maps_url'],
      googleMapsDirectionsUrl: json['google_maps_directions_url'],
      instagramUrl: json['instagram_url'],
      youtubeUrl: json['youtube_url'],
      eventHashtag: json['event_hashtag'],
      dressCode: json['dress_code'],
      coverImageUrl: json['cover_image_url'] ?? json['cover_image'],
      isPublished: json['is_published'] ?? false,
      qrImageUrl: qrImg,
      targetUrl: target,
      capacity: json['capacity'] ?? 100,
      guestCount: json['guest_count'] ?? json['confirmed_guests'] ?? 0,
      organizerName: json['organizer_name'],
      organizerContact: json['organizer_contact'],
      qrUuid: qrId,
      downloadPngUrl: pngUrl,
      downloadPdfUrl: pdfUrl,
      photos: photoList,
    );
  }

  bool get isActive => isPublished;

  String get eventTypeName {
    switch (eventType.toLowerCase()) {
      case 'wedding': return 'Wedding';
      case 'birthday': return 'Birthday';
      case 'engagement': return 'Engagement';
      case 'anniversary': return 'Anniversary';
      case 'housewarming': return 'Housewarming';
      case 'graduation': return 'Graduation';
      default: return 'Celebration';
    }
  }

  String get eventTypeIcon {
    switch (eventType.toLowerCase()) {
      case 'wedding': return '💍';
      case 'birthday': return '🎂';
      case 'engagement': return '💑';
      case 'anniversary': return '❤️';
      case 'housewarming': return '🏠';
      case 'graduation': return '🎓';
      default: return '🎉';
    }
  }

  String get statusText {
    try {
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      if (eventDate == todayStr) return 'Live Today';
      final evDate = DateTime.parse(eventDate);
      if (evDate.isAfter(now)) return 'Upcoming';
      return 'Completed';
    } catch (_) {
      return isPublished ? 'Live' : 'Draft';
    }
  }

  String get shareMessage {
    final navUrl = googleMapsDirectionsUrl ?? googleMapsUrl ?? 'https://maps.google.com/?q=${Uri.encodeComponent("$venueName $venueAddress")}';
    final invUrl = targetUrl ?? 'https://qroutex.com/events/e/$slug/';

    return '''
$eventTypeIcon *You're Cordially Invited!* $eventTypeIcon
*$title*
Hosted with love by: $hostNames

📅 *Date:* $eventDate ${eventTime != null ? "at $eventTime" : ""}
📍 *Venue:* $venueName
$venueAddress

🗺️ *Turn-by-Turn GPS Navigation:*
$navUrl

💌 *Digital Invitation & QR Pass:*
$invUrl

_Powered by QRouteX (qroutex.com)_
'''.trim();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'event_type': eventType,
      'host_names': hostNames,
      'description': description,
      'event_date': eventDate,
      'event_time': eventTime,
      'venue_name': venueName,
      'venue_address': venueAddress,
      'maps_url': googleMapsUrl,
      'google_maps_directions_url': googleMapsDirectionsUrl,
      'instagram_url': instagramUrl,
      'youtube_url': youtubeUrl,
      'event_hashtag': eventHashtag,
      'dress_code': dressCode,
      'cover_image_url': coverImageUrl,
      'is_published': isPublished,
      'capacity': capacity,
      'guest_count': guestCount,
      'organizer_name': organizerName,
      'organizer_contact': organizerContact,
      'photos': photos,
      if (qrImageUrl != null || targetUrl != null || qrUuid != null)
        'qr_code': {
          'uuid': qrUuid,
          'image_url': qrImageUrl,
          'target_url': targetUrl,
          'download_png_url': downloadPngUrl,
          'download_pdf_url': downloadPdfUrl,
        },
    };
  }
}
