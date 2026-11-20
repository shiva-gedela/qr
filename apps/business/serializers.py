"""
apps/business/serializers.py

Django REST Framework serializers for Business Profiles and Services.
"""

from rest_framework import serializers
from .models import Business, BusinessService, BusinessBooking
from apps.qrcodes.serializers import QRCodeSerializer


class BusinessServiceSerializer(serializers.ModelSerializer):
    """Serializer for Business Products and Services."""
    price_display = serializers.CharField(read_only=True)
    image_url = serializers.CharField(read_only=True)

    class Meta:
        model = BusinessService
        fields = [
            'id', 'business', 'name', 'description', 'price',
            'price_type', 'price_display', 'image', 'image_url',
            'order', 'is_available', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'business', 'created_at', 'updated_at']


class BusinessListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing user's business profiles."""
    qr_code = QRCodeSerializer(read_only=True)
    category_display = serializers.CharField(source='get_category_display', read_only=True)
    service_count = serializers.SerializerMethodField()
    logo_url = serializers.CharField(read_only=True)
    cover_image_url = serializers.CharField(read_only=True)

    class Meta:
        model = Business
        fields = [
            'id', 'uuid', 'name', 'tagline', 'category', 'category_display',
            'slug', 'logo', 'logo_url', 'cover_image', 'cover_image_url',
            'city', 'state', 'phone', 'is_active', 'is_verified',
            'service_count', 'qr_code', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'uuid', 'slug', 'created_at', 'updated_at']

    def get_service_count(self, obj):
        return obj.services.count()


class BusinessDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer including all contact fields, services, and QR code."""
    services = BusinessServiceSerializer(many=True, read_only=True)
    qr_code = QRCodeSerializer(read_only=True)
    category_display = serializers.CharField(source='get_category_display', read_only=True)
    full_address = serializers.CharField(read_only=True)
    whatsapp_url = serializers.CharField(read_only=True)
    phone_url = serializers.CharField(read_only=True)
    logo_url = serializers.CharField(read_only=True)
    cover_image_url = serializers.CharField(read_only=True)

    class Meta:
        model = Business
        fields = [
            'id', 'uuid', 'owner', 'name', 'tagline', 'category', 'category_display',
            'description', 'slug', 'logo', 'logo_url', 'cover_image', 'cover_image_url',
            'phone', 'whatsapp', 'email', 'website',
            'instagram', 'facebook', 'twitter', 'linkedin', 'youtube',
            'address', 'city', 'state', 'pincode', 'maps_url', 'full_address',
            'working_hours', 'is_active', 'is_verified',
            'whatsapp_url', 'phone_url', 'services', 'qr_code',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'uuid', 'owner', 'slug', 'created_at', 'updated_at']


class BusinessPublicSerializer(serializers.ModelSerializer):
    """Public read-only serializer for mobile app QR scan & landing page."""
    services = serializers.SerializerMethodField()
    category_display = serializers.CharField(source='get_category_display', read_only=True)
    full_address = serializers.CharField(read_only=True)
    whatsapp_url = serializers.CharField(read_only=True)
    phone_url = serializers.CharField(read_only=True)
    logo_url = serializers.CharField(read_only=True)
    cover_image_url = serializers.CharField(read_only=True)

    class Meta:
        model = Business
        fields = [
            'id', 'uuid', 'name', 'tagline', 'category', 'category_display',
            'description', 'slug', 'logo_url', 'cover_image_url',
            'phone', 'whatsapp', 'email', 'website',
            'instagram', 'facebook', 'twitter', 'linkedin', 'youtube',
            'address', 'city', 'state', 'pincode', 'maps_url', 'full_address',
            'working_hours', 'whatsapp_url', 'phone_url', 'services',
        ]

    def get_services(self, obj):
        services = obj.get_active_services()
        return BusinessServiceSerializer(services, many=True).data


class BusinessBookingSerializer(serializers.ModelSerializer):
    """Serializer for business bookings and table reservations."""
    id = serializers.CharField(source='booking_code', read_only=True)
    business_id = serializers.IntegerField(source='business.id', read_only=True)
    business_name = serializers.CharField(source='business.name', read_only=True)
    business_category = serializers.CharField(source='business.get_category_display', read_only=True)

    class Meta:
        model = BusinessBooking
        fields = [
            'id', 'booking_code', 'business', 'business_id', 'business_name', 'business_category',
            'service', 'service_name', 'service_price',
            'customer_name', 'customer_phone', 'customer_email',
            'date', 'time_slot', 'guests_count', 'special_requests',
            'status', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'booking_code', 'created_at', 'updated_at']

    def validate(self, attrs):
        business = attrs.get('business')
        date = attrs.get('date')
        time_slot = attrs.get('time_slot')
        phone = attrs.get('customer_phone')

        if business and date and time_slot and phone:
            existing = BusinessBooking.objects.filter(
                business=business,
                date=date,
                time_slot=time_slot,
                customer_phone=phone,
            ).exclude(status='cancelled')
            if self.instance:
                existing = existing.exclude(pk=self.instance.pk)
            if existing.exists():
                raise serializers.ValidationError(
                    "You already have an active booking for this business at this date and time slot."
                )
        return attrs

