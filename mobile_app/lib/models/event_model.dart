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
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    String? qrImg;
    String? target;
    if (json['qr_code'] != null && json['qr_code'] is Map) {
      qrImg = json['qr_code']['qr_image_url'] ?? json['qr_code']['qr_image'];
      target = json['qr_code']['target_url'];
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
    );
  }
}
