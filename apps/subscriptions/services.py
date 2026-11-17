"""
apps/subscriptions/services.py

Razorpay order creation, payment signature verification, subscription provisioning,
and default tier seeding.
"""

import hmac
import hashlib
import uuid
from decimal import Decimal
from datetime import timedelta
from django.conf import settings
from django.utils import timezone
from django.contrib.auth import get_user_model

from .models import SubscriptionPlan, Subscription, Payment, AuditLog

User = get_user_model()


def get_razorpay_client():
    """Returns initialized Razorpay Client or None if library not loaded."""
    key_id = getattr(settings, 'RAZORPAY_KEY_ID', '')
    key_secret = getattr(settings, 'RAZORPAY_KEY_SECRET', '')
    if key_id and key_secret:
        try:
            import razorpay
            return razorpay.Client(auth=(key_id, key_secret))
        except Exception:
            return None
    return None


def seed_default_plans():
    """Ensure the 4 core subscription plans exist in the database."""
    default_plans = [
        {
            'code': 'free',
            'name': 'Free Forever',
            'badge': 'FREE',
            'price': Decimal('0.00'),
            'duration_days': 0,
            'max_events': 1,
            'max_storage_mb': 50,
            'custom_qr_allowed': False,
            'guest_upload_allowed': False,
            'business_profile_allowed': False,
            'tabletop_standee_pdf': False,
            'remove_branding': False,
            'order': 1,
            'description': 'Essential event invitation with standard QR code and 50MB photo storage.',
        },
        {
            'code': 'premium_event',
            'name': 'Premium Event Plan',
            'badge': 'POPULAR',
            'price': Decimal('999.00'),
            'duration_days': 365,
            'max_events': 5,
            'max_storage_mb': 1024,
            'custom_qr_allowed': True,
            'guest_upload_allowed': True,
            'business_profile_allowed': False,
            'tabletop_standee_pdf': True,
            'remove_branding': True,
            'order': 2,
            'description': 'Full event mini-website with custom QR colors & logo, 1GB media gallery, and printable PDF cards.',
        },
        {
            'code': 'wedding_package',
            'name': 'Wedding Package',
            'badge': 'BEST VALUE',
            'price': Decimal('2499.00'),
            'duration_days': 365,
            'max_events': 3,
            'max_storage_mb': 5120,
            'custom_qr_allowed': True,
            'guest_upload_allowed': True,
            'business_profile_allowed': True,
            'tabletop_standee_pdf': True,
            'remove_branding': True,
            'order': 3,
            'description': 'The ultimate grand wedding experience with 5GB storage, live guest photo sharing with moderation queue, countdown timer, and printable standees.',
        },
        {
            'code': 'business_annual',
            'name': 'Business Annual Subscription',
            'badge': 'FOR BUSINESS',
            'price': Decimal('4999.00'),
            'duration_days': 365,
            'max_events': 10,
            'max_storage_mb': 2048,
            'custom_qr_allowed': True,
            'guest_upload_allowed': True,
            'business_profile_allowed': True,
            'tabletop_standee_pdf': True,
            'remove_branding': True,
            'order': 4,
            'description': 'Complete digital business profile, unlimited products/services catalog, vCard 3.0 phonebook saving, and tabletop standee PDF generator.',
        },
    ]

    created_plans = []
    for p in default_plans:
        code = p.pop('code')
        obj, _ = SubscriptionPlan.objects.update_or_create(code=code, defaults=p)
        created_plans.append(obj)
    return created_plans


def create_razorpay_order(user, plan):
    """
    Creates an order on Razorpay and initializes a Payment record.
    Supports real Razorpay client as well as test/mock sandbox fallback.
    """
    client = get_razorpay_client()
    invoice_number = Payment.generate_invoice_number()
    amount_in_paise = plan.price_in_paise

    razorpay_order_id = None
    if client and amount_in_paise > 0:
        try:
            order_data = {
                'amount': amount_in_paise,
                'currency': 'INR',
                'receipt': invoice_number,
                'notes': {
                    'user_id': str(user.pk),
                    'plan_code': plan.code,
                    'invoice_number': invoice_number,
                }
            }
            order = client.order.create(data=order_data)
            razorpay_order_id = order['id']
        except Exception:
            razorpay_order_id = None

    # Fallback to test/dev order ID if Razorpay client is offline/mock
    if not razorpay_order_id:
        razorpay_order_id = f"order_mock_{uuid.uuid4().hex[:14]}"

    payment = Payment.objects.create(
        user=user,
        plan=plan,
        invoice_number=invoice_number,
        amount=plan.price,
        currency='INR',
        razorpay_order_id=razorpay_order_id,
        status='created'
    )

    return {
        'payment': payment,
        'order_id': razorpay_order_id,
        'amount': amount_in_paise,
        'amount_display': plan.price,
        'currency': 'INR',
        'key_id': getattr(settings, 'RAZORPAY_KEY_ID', 'rzp_test_placeholder_key'),
        'invoice_number': invoice_number,
        'plan_name': plan.name,
    }


def verify_and_activate_payment(user, razorpay_order_id, razorpay_payment_id, razorpay_signature, ip_address=''):
    """
    Verifies Razorpay payment signature, captures transaction, and activates subscription.
    """
    try:
        payment = Payment.objects.get(razorpay_order_id=razorpay_order_id, user=user)
    except Payment.DoesNotExist:
        return False, "Order not found.", None

    # Signature verification
    is_valid_sig = False
    client = get_razorpay_client()
    key_secret = getattr(settings, 'RAZORPAY_KEY_SECRET', '')

    if razorpay_order_id.startswith('order_mock_'):
        # Development sandbox mock verification
        is_valid_sig = True
    elif client and key_secret:
        try:
            # Razorpay HMAC SHA256 verification
            payload = f"{razorpay_order_id}|{razorpay_payment_id}"
            generated_sig = hmac.new(
                key_secret.encode('utf-8'),
                payload.encode('utf-8'),
                hashlib.sha256
            ).hexdigest()
            is_valid_sig = (generated_sig == razorpay_signature)
        except Exception:
            is_valid_sig = False
    else:
        # Development mode without external credentials
        is_valid_sig = True

    if not is_valid_sig:
        payment.status = 'failed'
        payment.save()
        AuditLog.objects.create(
            user=user,
            action='PAYMENT_FAILED',
            resource_type='Payment',
            resource_id=str(payment.pk),
            ip_address=ip_address,
            details=f"Signature verification failed for order {razorpay_order_id}"
        )
        return False, "Payment signature verification failed.", payment

    # Update Payment record
    payment.razorpay_payment_id = razorpay_payment_id
    payment.razorpay_signature = razorpay_signature
    payment.status = 'captured'
    payment.save()

    # Calculate Subscription duration
    now = timezone.now()
    if payment.plan.duration_days > 0:
        end_date = now + timedelta(days=payment.plan.duration_days)
    else:
        end_date = None

    # Deactivate any previous active subscriptions
    Subscription.objects.filter(user=user, status='active').update(status='expired')

    subscription = Subscription.objects.create(
        user=user,
        plan=payment.plan,
        status='active',
        start_date=now,
        end_date=end_date,
    )

    # Link payment to subscription
    payment.subscription = subscription
    payment.save()

    # Update User flags
    user.is_premium = True
    user.save(update_fields=['is_premium'])

    # Audit log
    AuditLog.objects.create(
        user=user,
        action='PAYMENT_SUCCESS',
        resource_type='Payment',
        resource_id=str(payment.pk),
        ip_address=ip_address,
        details=f"Payment of ₹{payment.amount} captured for plan {payment.plan.name} (Invoice: {payment.invoice_number})"
    )

    return True, "Payment successful and plan activated!", payment
