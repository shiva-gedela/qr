"""
apps/qrcodes/admin.py - Django admin configuration for QR codes.
"""

from django.contrib import admin
from django.utils.html import format_html
from .models import QRCode


@admin.register(QRCode)
class QRCodeAdmin(admin.ModelAdmin):
    list_display = ['uuid', 'qr_type', 'get_target_preview', 'fill_color', 'back_color', 'scan_count', 'get_thumbnail', 'created_at']
    list_filter = ['qr_type', 'created_at']
    search_fields = ['uuid', 'target_url', 'event__title']
    readonly_fields = ['uuid', 'scan_count', 'last_scanned_at', 'created_at', 'updated_at', 'get_qr_preview']

    fieldsets = (
        ('Identifiers & Target', {
            'fields': ('uuid', 'qr_type', 'event', 'business', 'invitation', 'target_url'),
        }),
        ('Branding & Colors', {
            'fields': ('fill_color', 'back_color', 'logo', 'qr_image', 'get_qr_preview'),
        }),
        ('Analytics & Metrics', {
            'fields': ('scan_count', 'last_scanned_at'),
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
        }),
    )

    def get_target_preview(self, obj):
        if obj.event:
            return obj.event.title
        if obj.invitation:
            return f"{obj.invitation.guest.name} - {obj.invitation.guest.event.title}"
        return obj.target_url
    get_target_preview.short_description = 'Target'

    def get_thumbnail(self, obj):
        if obj.qr_image:
            return format_html('<img src="{}" width="40" height="40" style="object-fit:cover; border-radius:4px; border:1px solid #ccc;"/>', obj.qr_image.url)
        return 'No Image'
    get_thumbnail.short_description = 'Preview'

    def get_qr_preview(self, obj):
        if obj.qr_image:
            return format_html('<img src="{}" width="180" height="180" style="object-fit:cover; border-radius:8px; border:1px solid #ddd;"/>', obj.qr_image.url)
        return 'No Image'
    get_qr_preview.short_description = 'Full Preview'
