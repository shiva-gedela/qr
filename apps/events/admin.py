"""
apps/events/admin.py - Admin panel configuration for events.
"""

from django.contrib import admin
from .models import Event, EventCheckIn, EventGuest, EventMedia, EventStaff, Invitation, QRScanLog


class EventMediaInline(admin.TabularInline):
    model = EventMedia
    extra = 0
    fields = ['media_type', 'file', 'caption', 'category', 'is_approved', 'is_public']
    readonly_fields = ['file_size']


@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ['title', 'event_type', 'owner', 'event_date', 'is_published', 'created_at']
    list_filter = ['event_type', 'is_published', 'is_private']
    search_fields = ['title', 'host_names', 'owner__email', 'slug']
    readonly_fields = ['uuid', 'slug', 'created_at', 'updated_at']
    prepopulated_fields = {}
    inlines = [EventMediaInline]
    ordering = ['-created_at']

    actions = ['publish_events', 'unpublish_events']

    def publish_events(self, request, queryset):
        queryset.update(is_published=True)
    publish_events.short_description = "Publish selected events"

    def unpublish_events(self, request, queryset):
        queryset.update(is_published=False)
    unpublish_events.short_description = "Unpublish selected events"


@admin.register(EventMedia)
class EventMediaAdmin(admin.ModelAdmin):
    list_display = ['event', 'media_type', 'category', 'uploaded_by', 'is_approved', 'is_public', 'uploaded_at']
    list_filter = ['media_type', 'category', 'is_approved', 'is_public']
    search_fields = ['event__title', 'uploaded_by__email', 'caption']
    actions = ['approve_media', 'unapprove_media']

    def approve_media(self, request, queryset):
        queryset.update(is_approved=True)
    approve_media.short_description = "Approve selected media"

    def unapprove_media(self, request, queryset):
        queryset.update(is_approved=False)
    unapprove_media.short_description = "Unapprove selected media"


@admin.register(EventGuest)
class EventGuestAdmin(admin.ModelAdmin):
    list_display = ['name', 'event', 'invitation_type', 'guest_count', 'status']
    list_filter = ['invitation_type', 'status']
    search_fields = ['name', 'email', 'mobile', 'event__title']


@admin.register(Invitation)
class InvitationAdmin(admin.ModelAdmin):
    list_display = ['guest', 'status', 'expires_at', 'created_at']
    list_filter = ['status']
    search_fields = ['guest__name', 'guest__event__title']
    readonly_fields = ['token', 'created_at']


@admin.register(EventStaff)
class EventStaffAdmin(admin.ModelAdmin):
    list_display = ['event', 'user', 'role', 'created_at']
    list_filter = ['role']
    search_fields = ['event__title', 'user__email']


@admin.register(EventCheckIn)
class EventCheckInAdmin(admin.ModelAdmin):
    list_display = ['invitation', 'checked_in_by', 'checked_in_at']
    list_filter = ['checked_in_at']
    search_fields = ['invitation__guest__name', 'invitation__guest__event__title']
    readonly_fields = ['checked_in_at']


@admin.register(QRScanLog)
class QRScanLogAdmin(admin.ModelAdmin):
    list_display = ['event', 'invitation', 'scanned_by', 'result', 'reason', 'scanned_at']
    list_filter = ['result', 'scanned_at']
    search_fields = ['event__title', 'invitation__guest__name', 'scanned_by__email']
    readonly_fields = ['event', 'invitation', 'scanned_by', 'result', 'reason', 'scanned_at']
