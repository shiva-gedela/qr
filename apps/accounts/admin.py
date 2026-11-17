"""
apps/accounts/admin.py - Admin panel configuration for accounts.
"""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Custom admin for the extended User model."""

    list_display = ['email', 'get_full_name', 'phone', 'email_verified', 'is_premium', 'is_active', 'created_at']
    list_filter = ['email_verified', 'is_premium', 'is_active', 'is_staff']
    search_fields = ['email', 'first_name', 'last_name', 'phone']
    ordering = ['-created_at']
    readonly_fields = ['created_at', 'updated_at', 'email_verification_token']

    fieldsets = BaseUserAdmin.fieldsets + (
        ('EventConnect QR Fields', {
            'fields': ('phone', 'avatar', 'bio', 'email_verified', 'email_verification_token', 'is_premium'),
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
        }),
    )

    add_fieldsets = BaseUserAdmin.add_fieldsets + (
        ('Profile', {
            'fields': ('email', 'first_name', 'last_name', 'phone'),
        }),
    )

    actions = ['mark_email_verified', 'mark_premium', 'revoke_premium']

    def mark_email_verified(self, request, queryset):
        queryset.update(email_verified=True)
        self.message_user(request, f"{queryset.count()} user(s) marked as email verified.")
    mark_email_verified.short_description = "Mark selected users as email verified"

    def mark_premium(self, request, queryset):
        queryset.update(is_premium=True)
        self.message_user(request, f"{queryset.count()} user(s) upgraded to premium.")
    mark_premium.short_description = "Upgrade selected users to premium"

    def revoke_premium(self, request, queryset):
        queryset.update(is_premium=False)
        self.message_user(request, f"{queryset.count()} user(s) premium revoked.")
    revoke_premium.short_description = "Revoke premium from selected users"
