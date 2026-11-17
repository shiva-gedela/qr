"""
apps/business/admin.py

Django Admin configuration for Business profiles and Products/Services.
"""

from django.contrib import admin
from .models import Business, BusinessService


class BusinessServiceInline(admin.TabularInline):
    model = BusinessService
    extra = 1
    fields = ('name', 'price', 'price_type', 'is_available', 'order')


@admin.register(Business)
class BusinessAdmin(admin.ModelAdmin):
    list_display = (
        'name', 'owner', 'category', 'city', 'phone',
        'is_active', 'is_verified', 'created_at',
    )
    list_filter = ('category', 'is_active', 'is_verified', 'created_at')
    search_fields = ('name', 'tagline', 'owner__email', 'phone', 'city')
    prepopulated_fields = {'slug': ('name',)}
    readonly_fields = ('uuid', 'created_at', 'updated_at')
    inlines = [BusinessServiceInline]

    fieldsets = (
        ('Basic Information', {
            'fields': ('owner', 'name', 'tagline', 'category', 'description', 'slug', 'uuid')
        }),
        ('Visual Branding', {
            'fields': ('logo', 'cover_image')
        }),
        ('Direct Contact', {
            'fields': ('phone', 'whatsapp', 'email', 'website')
        }),
        ('Social Links', {
            'classes': ('collapse',),
            'fields': ('instagram', 'facebook', 'twitter', 'linkedin', 'youtube')
        }),
        ('Location & Maps', {
            'fields': ('address', 'city', 'state', 'pincode', 'maps_url')
        }),
        ('Operating Hours & Settings', {
            'fields': ('working_hours', 'is_active', 'is_verified')
        }),
        ('Timestamps', {
            'classes': ('collapse',),
            'fields': ('created_at', 'updated_at')
        }),
    )


@admin.register(BusinessService)
class BusinessServiceAdmin(admin.ModelAdmin):
    list_display = ('name', 'business', 'price', 'price_type', 'is_available', 'order', 'created_at')
    list_filter = ('price_type', 'is_available', 'created_at')
    search_fields = ('name', 'description', 'business__name')
