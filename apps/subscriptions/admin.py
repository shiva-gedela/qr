"""
apps/subscriptions/admin.py

Standard Django Admin registrations for Subscriptions, Plans, Payments, and Audit Logs.
"""

from django.contrib import admin
from .models import SubscriptionPlan, Subscription, Payment, AuditLog


@admin.register(SubscriptionPlan)
class SubscriptionPlanAdmin(admin.ModelAdmin):
    list_display = ('name', 'code', 'price', 'duration_days', 'max_events', 'max_storage_mb', 'is_active', 'order')
    list_editable = ('is_active', 'order')
    list_filter = ('is_active', 'custom_qr_allowed', 'guest_upload_allowed')
    search_fields = ('name', 'code', 'description')


@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin):
    list_display = ('user', 'plan', 'status', 'start_date', 'end_date', 'is_valid', 'created_at')
    list_filter = ('status', 'plan', 'created_at')
    search_fields = ('user__email', 'user__first_name', 'user__last_name', 'plan__name')
    readonly_fields = ('uuid', 'created_at', 'updated_at')


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ('invoice_number', 'user', 'plan', 'amount', 'currency', 'status', 'razorpay_order_id', 'created_at')
    list_filter = ('status', 'currency', 'created_at')
    search_fields = ('invoice_number', 'user__email', 'razorpay_order_id', 'razorpay_payment_id')
    readonly_fields = ('uuid', 'invoice_number', 'created_at', 'updated_at')


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ('created_at', 'action', 'user', 'resource_type', 'resource_id', 'ip_address')
    list_filter = ('action', 'resource_type', 'created_at')
    search_fields = ('user__email', 'action', 'details', 'resource_id')
    readonly_fields = ('created_at',)
