"""
apps/subscriptions/serializers.py

DRF Serializers for Subscription Plans, Subscriptions, and Payments.
"""

from rest_framework import serializers
from .models import SubscriptionPlan, Subscription, Payment


class SubscriptionPlanSerializer(serializers.ModelSerializer):
    """Serializer for available pricing tiers."""
    price_display = serializers.SerializerMethodField()

    class Meta:
        model = SubscriptionPlan
        fields = [
            'id', 'code', 'name', 'badge', 'description', 'price',
            'price_display', 'duration_days', 'max_events', 'max_storage_mb',
            'custom_qr_allowed', 'guest_upload_allowed', 'business_profile_allowed',
            'tabletop_standee_pdf', 'remove_branding', 'is_active', 'order',
        ]

    def get_price_display(self, obj):
        if obj.is_free:
            return "Free"
        return f"₹{obj.price:,.2f}"


class SubscriptionSerializer(serializers.ModelSerializer):
    """Serializer for user's active subscription."""
    plan = SubscriptionPlanSerializer(read_only=True)
    is_valid = serializers.BooleanField(read_only=True)
    days_remaining = serializers.IntegerField(read_only=True)

    class Meta:
        model = Subscription
        fields = [
            'id', 'uuid', 'plan', 'status', 'start_date', 'end_date',
            'auto_renew', 'is_valid', 'days_remaining', 'created_at',
        ]
        read_only_fields = ['id', 'uuid', 'created_at']


class PaymentSerializer(serializers.ModelSerializer):
    """Serializer for user payments and invoices."""
    plan_name = serializers.CharField(source='plan.name', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = Payment
        fields = [
            'id', 'uuid', 'invoice_number', 'plan_name', 'amount', 'currency',
            'razorpay_order_id', 'razorpay_payment_id', 'status', 'status_display',
            'created_at',
        ]
        read_only_fields = ['id', 'uuid', 'invoice_number', 'created_at']
