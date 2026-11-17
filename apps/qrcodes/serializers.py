"""
apps/qrcodes/serializers.py - DRF serializers for QR codes.
"""

from rest_framework import serializers
from .models import QRCode


class QRCodeSerializer(serializers.ModelSerializer):
    """Serializer for QR code details and download links."""

    image_url = serializers.SerializerMethodField()
    download_png_url = serializers.SerializerMethodField()
    download_pdf_url = serializers.SerializerMethodField()
    scan_url = serializers.SerializerMethodField()

    class Meta:
        model = QRCode
        fields = [
            'id', 'uuid', 'qr_type', 'target_url',
            'fill_color', 'back_color', 'image_url',
            'download_png_url', 'download_pdf_url', 'scan_url',
            'scan_count', 'last_scanned_at', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'uuid', 'scan_count', 'last_scanned_at', 'created_at', 'updated_at']

    def get_image_url(self, obj):
        request = self.context.get('request')
        if obj.qr_image:
            return request.build_absolute_uri(obj.qr_image.url) if request else obj.qr_image.url
        return ''

    def get_download_png_url(self, obj):
        request = self.context.get('request')
        url = obj.get_download_png_url()
        return request.build_absolute_uri(url) if request else url

    def get_download_pdf_url(self, obj):
        request = self.context.get('request')
        url = obj.get_download_pdf_url()
        return request.build_absolute_uri(url) if request else url

    def get_scan_url(self, obj):
        request = self.context.get('request')
        url = obj.get_scan_url()
        return request.build_absolute_uri(url) if request else url
