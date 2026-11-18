"""
apps/events/serializers.py - DRF serializers for events.
"""

from rest_framework import serializers
from django.urls import reverse
from .models import Event, EventGuest, EventMedia, EventStaff


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
            'organizer_name', 'organizer_contact', 'capacity', 'registration_start', 'registration_end',
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
            'organizer_name', 'organizer_contact', 'capacity', 'registration_start', 'registration_end',
            'instagram_url', 'facebook_url', 'youtube_url', 'event_hashtag', 'dress_code',
            'is_published', 'is_private', 'private_password',
        ]

    def validate(self, data):
        registration_start = data.get('registration_start')
        registration_end = data.get('registration_end')
        if registration_start and registration_end and registration_end < registration_start:
            raise serializers.ValidationError(
                {'registration_end': 'Registration must end after it starts.'}
            )
        return data


class EventGuestSerializer(serializers.ModelSerializer):
    invitation_url = serializers.SerializerMethodField()
    qr_image_url = serializers.SerializerMethodField()
    qr_download_url = serializers.SerializerMethodField()
    pdf_download_url = serializers.SerializerMethodField()
    invitation_status = serializers.SerializerMethodField()

    class Meta:
        model = EventGuest
        fields = [
            'id', 'name', 'mobile', 'email', 'guest_count', 'invitation_type', 'status',
            'invitation_status', 'invitation_url', 'qr_image_url', 'qr_download_url',
            'pdf_download_url', 'created_at',
        ]
        read_only_fields = ['id', 'invitation_status', 'invitation_url', 'qr_image_url', 'qr_download_url', 'pdf_download_url', 'created_at']

    def get_invitation_status(self, obj):
        invitation = getattr(obj, 'invitation', None)
        if not invitation:
            return None
        return 'expired' if invitation.is_expired and invitation.status == 'active' else invitation.status

    def _get_invitation_url(self, obj):
        invitation = getattr(obj, 'invitation', None)
        if not invitation:
            return ''
        path = reverse('event_invitation', kwargs={'token': invitation.token})
        request = self.context.get('request')
        return request.build_absolute_uri(path) if request else path

    def get_invitation_url(self, obj):
        return self._get_invitation_url(obj)

    def get_qr_image_url(self, obj):
        qr = getattr(getattr(obj, 'invitation', None), 'qr_code', None)
        request = self.context.get('request')
        if not qr or not qr.qr_image:
            return ''
        return request.build_absolute_uri(qr.qr_image.url) if request else qr.qr_image.url

    def get_qr_download_url(self, obj):
        qr = getattr(getattr(obj, 'invitation', None), 'qr_code', None)
        if not qr:
            return ''
        path = qr.get_download_png_url()
        request = self.context.get('request')
        return request.build_absolute_uri(path) if request else path

    def get_pdf_download_url(self, obj):
        qr = getattr(getattr(obj, 'invitation', None), 'qr_code', None)
        if not qr:
            return ''
        path = qr.get_download_pdf_url()
        request = self.context.get('request')
        return request.build_absolute_uri(path) if request else path

    def validate_guest_count(self, value):
        if value < 1:
            raise serializers.ValidationError('Guest count must be at least one.')
        return value


class EventStaffSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(source='user.email', read_only=True)
    name = serializers.CharField(source='user.get_full_name', read_only=True)

    class Meta:
        model = EventStaff
        fields = ['id', 'email', 'name', 'role', 'created_at']
        read_only_fields = ['id', 'name', 'created_at']
