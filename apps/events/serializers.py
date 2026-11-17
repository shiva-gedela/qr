"""
apps/events/serializers.py - DRF serializers for events.
"""

from rest_framework import serializers
from .models import Event, EventMedia


class EventMediaSerializer(serializers.ModelSerializer):
    file_url = serializers.SerializerMethodField()
    thumbnail_url = serializers.SerializerMethodField()
    category_display = serializers.CharField(source='get_category_display', read_only=True)
    uploaded_by_name = serializers.SerializerMethodField()

    class Meta:
        model = EventMedia
        fields = [
            'id', 'media_type', 'file_url', 'thumbnail_url',
            'caption', 'category', 'category_display',
            'is_approved', 'is_public', 'file_size', 'file_size_mb',
            'uploaded_by_name', 'uploaded_at',
        ]
        read_only_fields = ['id', 'file_size', 'file_size_mb', 'uploaded_at']

    def get_file_url(self, obj):
        request = self.context.get('request')
        if obj.file:
            return request.build_absolute_uri(obj.file.url) if request else obj.file.url
        return ''

    def get_thumbnail_url(self, obj):
        request = self.context.get('request')
        if obj.thumbnail:
            return request.build_absolute_uri(obj.thumbnail.url) if request else obj.thumbnail.url
        return self.get_file_url(obj)

    def get_uploaded_by_name(self, obj):
        if obj.uploaded_by:
            return obj.uploaded_by.get_full_name()
        return 'Guest'


class EventSerializer(serializers.ModelSerializer):
    """Full event serializer for API."""

    owner_name = serializers.SerializerMethodField()
    public_url = serializers.SerializerMethodField()
    cover_image_url = serializers.SerializerMethodField()
    photos = serializers.SerializerMethodField()
    videos = serializers.SerializerMethodField()
    qr_code = serializers.SerializerMethodField()
    storage_info = serializers.SerializerMethodField()
    categories = serializers.SerializerMethodField()
    event_type_display = serializers.CharField(source='get_event_type_display', read_only=True)
    google_maps_directions_url = serializers.CharField(read_only=True)

    class Meta:
        model = Event
        fields = [
            'id', 'uuid', 'slug', 'event_type', 'event_type_display',
            'title', 'host_names', 'description',
            'event_date', 'event_time', 'event_end_date', 'event_end_time',
            'venue_name', 'venue_address', 'maps_url', 'google_maps_directions_url',
            'instagram_url', 'facebook_url', 'youtube_url', 'event_hashtag', 'dress_code',
            'cover_image_url', 'is_published', 'is_private',
            'allow_guest_uploads', 'require_media_approval', 'max_storage_mb',
            'owner_name', 'public_url', 'photos', 'videos', 'qr_code',
            'storage_info', 'categories',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'uuid', 'slug', 'created_at', 'updated_at']

    def get_storage_info(self, obj):
        return {
            'used_mb': obj.used_storage_mb,
            'max_mb': obj.max_storage_mb,
            'percentage': obj.storage_percentage,
            'is_full': obj.is_storage_full,
        }

    def get_categories(self, obj):
        return obj.get_categories_with_counts()

    def get_owner_name(self, obj):
        return obj.owner.get_full_name()

    def get_public_url(self, obj):
        request = self.context.get('request')
        if request:
            return request.build_absolute_uri(obj.get_absolute_url())
        return obj.get_absolute_url()

    def get_cover_image_url(self, obj):
        return obj.cover_image_url

    def get_photos(self, obj):
        return EventMediaSerializer(obj.get_photos(), many=True).data

    def get_videos(self, obj):
        return EventMediaSerializer(obj.get_videos(), many=True).data

    def get_qr_code(self, obj):
        qr = getattr(obj, 'qr_code', None)
        if not qr:
            return None
        request = self.context.get('request')
        image_url = request.build_absolute_uri(qr.qr_image.url) if (request and qr.qr_image) else (qr.qr_image.url if qr.qr_image else '')
        png_url = request.build_absolute_uri(qr.get_download_png_url()) if request else qr.get_download_png_url()
        pdf_url = request.build_absolute_uri(qr.get_download_pdf_url()) if request else qr.get_download_pdf_url()
        scan_url = request.build_absolute_uri(qr.get_scan_url()) if request else qr.get_scan_url()
        return {
            'uuid': str(qr.uuid),
            'target_url': qr.target_url,
            'fill_color': qr.fill_color,
            'back_color': qr.back_color,
            'image_url': image_url,
            'download_png_url': png_url,
            'download_pdf_url': pdf_url,
            'scan_url': scan_url,
            'scan_count': qr.scan_count,
        }

    def validate(self, data):
        if data.get('is_private') and not data.get('private_password'):
            raise serializers.ValidationError(
                {"private_password": "Password required for private events."}
            )
        return data


class EventCreateSerializer(serializers.ModelSerializer):
    """Slim serializer for creating/updating events via API."""

    class Meta:
        model = Event
        fields = [
            'event_type', 'title', 'host_names', 'description',
            'event_date', 'event_time', 'event_end_date', 'event_end_time',
            'venue_name', 'venue_address', 'maps_url',
            'instagram_url', 'facebook_url', 'youtube_url', 'event_hashtag', 'dress_code',
            'is_published', 'is_private', 'private_password',
        ]
