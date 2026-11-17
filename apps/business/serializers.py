"""
apps/business/serializers.py

Django REST Framework serializers for Business Profiles and Services.
"""

from rest_framework import serializers
from .models import Business, BusinessService
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
