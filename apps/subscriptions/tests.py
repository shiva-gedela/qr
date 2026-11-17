"""
apps/subscriptions/tests.py

Comprehensive test suite for Phase 5:
- Subscriptions, Pricing Tiers & Entitlements
- Razorpay Order Creation & Payment Verification
- Tax Invoice PDF Generation
- Platform Admin Dashboard (Module 8)
- User Account Block/Unblock & Audit Logging
- Media Moderation Queue
- DRF REST API Endpoints for Subscriptions & Checkout
"""

from decimal import Decimal
from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from django.urls import reverse
from django.utils import timezone
from datetime import timedelta
from rest_framework import status
from rest_framework.test import APIClient

from apps.subscriptions.models import SubscriptionPlan, Subscription, Payment, AuditLog
from apps.subscriptions.services import (
    seed_default_plans,
    create_razorpay_order,
    verify_and_activate_payment,
)
from apps.events.models import Event, EventMedia
from apps.business.models import Business

User = get_user_model()


class SubscriptionsCoreTests(TestCase):
    """Test suite for Subscription models, services, and invoice PDF generation."""

    def setUp(self):
        self.plans = seed_default_plans()
        self.user = User.objects.create_user(
            username='subscriber@example.com',
            email='subscriber@example.com',
            password='TestPassword@123',
            first_name='Vikram',
            last_name='Mehta'
        )

    def test_default_plans_seeded(self):
        """Verify the 4 default subscription tiers and entitlements."""
        self.assertEqual(SubscriptionPlan.objects.count(), 4)
        free = SubscriptionPlan.objects.get(code='free')
        self.assertEqual(free.price, Decimal('0.00'))
        self.assertFalse(free.custom_qr_allowed)

        wedding = SubscriptionPlan.objects.get(code='wedding_package')
        self.assertEqual(wedding.price, Decimal('2499.00'))
        self.assertTrue(wedding.custom_qr_allowed)
        self.assertTrue(wedding.guest_upload_allowed)
        self.assertEqual(wedding.max_storage_mb, 5120)

        biz = SubscriptionPlan.objects.get(code='business_annual')
        self.assertEqual(biz.price, Decimal('4999.00'))
        self.assertTrue(biz.business_profile_allowed)

    def test_subscription_validity(self):
        """Test subscription active state and remaining days calculation."""
        plan = SubscriptionPlan.objects.get(code='premium_event')
        now = timezone.now()
        sub = Subscription.objects.create(
            user=self.user,
            plan=plan,
            status='active',
            start_date=now,
            end_date=now + timedelta(days=60)
        )
        self.assertTrue(sub.is_valid())
        self.assertTrue(59 <= sub.days_remaining <= 60)

        # Expired test
        sub.end_date = now - timedelta(days=1)
        sub.save()
        self.assertFalse(sub.is_valid())
        self.assertEqual(sub.days_remaining, 0)

    def test_razorpay_order_and_payment_activation(self):
        """Test order creation and signature verification flow."""
        plan = SubscriptionPlan.objects.get(code='premium_event')
        order_data = create_razorpay_order(self.user, plan)

        self.assertIn('order_id', order_data)
        self.assertIn('invoice_number', order_data)
        self.assertEqual(order_data['amount'], 99900)

        payment = order_data['payment']
        self.assertEqual(payment.status, 'created')

        # Verify payment with mock signature
        success, msg, verified_pay = verify_and_activate_payment(
            user=self.user,
            razorpay_order_id=order_data['order_id'],
            razorpay_payment_id='pay_test_verified_123',
            razorpay_signature='sig_test_valid',
            ip_address='127.0.0.1'
        )
        self.assertTrue(success)
        self.assertEqual(verified_pay.status, 'captured')
        self.assertIsNotNone(verified_pay.subscription)
        self.assertTrue(verified_pay.subscription.is_valid())

        # Check User model updated
        self.user.refresh_from_db()
        self.assertTrue(self.user.is_premium)

        # Check Audit Log
        log = AuditLog.objects.filter(action='PAYMENT_SUCCESS', user=self.user).first()
        self.assertIsNotNone(log)
        self.assertEqual(log.resource_type, 'Payment')

    def test_invoice_pdf_generation(self):
        """Test tax invoice PDF creation using ReportLab."""
        plan = SubscriptionPlan.objects.get(code='wedding_package')
        order_data = create_razorpay_order(self.user, plan)
        payment = order_data['payment']
        payment.status = 'captured'
        payment.razorpay_payment_id = 'pay_invoice_test_456'
        payment.save()

        pdf_buf = payment.generate_invoice_pdf()
        content = pdf_buf.getvalue()
        self.assertTrue(content.startswith(b'%PDF'))
        self.assertTrue(len(content) > 1000)


class SubscriptionsWebViewsTests(TestCase):
    """Test suite for user-facing subscription web views and checkout."""

    def setUp(self):
        self.client = Client()
        seed_default_plans()
        self.user = User.objects.create_user(
            username='buyer@example.com',
            email='buyer@example.com',
            password='TestPassword@123',
            first_name='Kavita',
            last_name='Iyer'
        )

    def test_pricing_page_public(self):
        """Pricing page is accessible to everyone."""
        response = self.client.get(reverse('pricing'))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Free Forever')
        self.assertContains(response, 'Premium Event Plan')
        self.assertContains(response, 'Wedding Package')
        self.assertContains(response, 'Business Annual Subscription')

    def test_checkout_requires_login(self):
        """Unauthenticated checkout redirects to login."""
        response = self.client.get(reverse('checkout', kwargs={'plan_code': 'premium_event'}))
        self.assertEqual(response.status_code, 302)

    def test_checkout_paid_plan(self):
        """Authenticated checkout presents Razorpay payment screen."""
        self.client.login(username='buyer@example.com', password='TestPassword@123')
        response = self.client.get(reverse('checkout', kwargs={'plan_code': 'premium_event'}))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Order Summary')
        self.assertContains(response, 'Pay ₹999 via Razorpay')

    def test_payment_verify_post(self):
        """Simulate payment callback and verify redirect to payment success page."""
        self.client.login(username='buyer@example.com', password='TestPassword@123')
        plan = SubscriptionPlan.objects.get(code='premium_event')
        order_data = create_razorpay_order(self.user, plan)

        post_data = {
            'razorpay_order_id': order_data['order_id'],
            'razorpay_payment_id': 'pay_simulated_789',
            'razorpay_signature': 'sig_simulated_valid',
        }
        response = self.client.post(reverse('payment_verify'), post_data)
        self.assertEqual(response.status_code, 302)
        self.assertIn('payment/success', response.url)

    def test_payment_history_and_invoice_download(self):
        """User can view past transactions and download invoice PDF."""
        self.client.login(username='buyer@example.com', password='TestPassword@123')
        plan = SubscriptionPlan.objects.get(code='wedding_package')
        order_data = create_razorpay_order(self.user, plan)
        verify_and_activate_payment(
            user=self.user,
            razorpay_order_id=order_data['order_id'],
            razorpay_payment_id='pay_history_001',
            razorpay_signature='sig_valid'
        )

        history_resp = self.client.get(reverse('payment_history'))
        self.assertEqual(history_resp.status_code, 200)
        self.assertContains(history_resp, order_data['invoice_number'])

        # Download invoice
        pdf_resp = self.client.get(reverse('download_invoice', kwargs={'invoice_number': order_data['invoice_number']}))
        self.assertEqual(pdf_resp.status_code, 200)
        self.assertEqual(pdf_resp['Content-Type'], 'application/pdf')
        self.assertIn(b'%PDF', pdf_resp.content[:10])


class AdminDashboardTests(TestCase):
    """Test suite for Module 8: Platform Admin Dashboard."""

    def setUp(self):
        self.client = Client()
        seed_default_plans()

        # Regular user
        self.regular_user = User.objects.create_user(
            username='user@example.com',
            email='user@example.com',
            password='TestPassword@123'
        )

        # Superadmin staff user
        self.admin_user = User.objects.create_superuser(
            username='sysadmin@example.com',
            email='sysadmin@example.com',
            password='TestPassword@123'
        )

        # Create test event & business
        self.event = Event.objects.create(
            owner=self.regular_user,
            title='Admin Test Gala',
            event_type='other',
            event_date=timezone.now().date() + timedelta(days=10),
            is_published=True
        )
        self.business = Business.objects.create(
            owner=self.regular_user,
            name='Test Admin Enterprise',
            category='tech',
            is_verified=False
        )

    def test_admin_dashboard_security(self):
        """Regular user receives 302/redirect to admin login when accessing platform-admin."""
        self.client.login(username='user@example.com', password='TestPassword@123')
        resp = self.client.get(reverse('admin_dashboard'))
        self.assertEqual(resp.status_code, 302)

    def test_admin_dashboard_staff_access(self):
        """Staff user can access overview metrics."""
        self.client.login(username='sysadmin@example.com', password='TestPassword@123')
        resp = self.client.get(reverse('admin_dashboard'))
        self.assertEqual(resp.status_code, 200)
        self.assertContains(resp, 'Platform Overview')
        self.assertContains(resp, 'Total Users')
        self.assertContains(resp, 'Total Revenue')

    def test_admin_user_block_unblock(self):
        """Admin can block and unblock user accounts and verify audit log."""
        self.client.login(username='sysadmin@example.com', password='TestPassword@123')
        toggle_url = reverse('admin_user_toggle_status', kwargs={'user_id': self.regular_user.pk})

        # Block
        resp = self.client.post(toggle_url)
        self.assertEqual(resp.status_code, 302)
        self.regular_user.refresh_from_db()
        self.assertFalse(self.regular_user.is_active)

        # Check AuditLog
        log = AuditLog.objects.filter(action='USER_BLOCK', resource_id=str(self.regular_user.pk)).first()
        self.assertIsNotNone(log)

        # Unblock
        resp2 = self.client.post(toggle_url)
        self.assertEqual(resp2.status_code, 302)
        self.regular_user.refresh_from_db()
        self.assertTrue(self.regular_user.is_active)

    def test_admin_business_toggle_verify(self):
        """Admin can toggle verified badge on business profiles."""
        self.client.login(username='sysadmin@example.com', password='TestPassword@123')
        url = reverse('admin_business_toggle_verify', kwargs={'business_id': self.business.pk})

        resp = self.client.post(url)
        self.assertEqual(resp.status_code, 302)
        self.business.refresh_from_db()
        self.assertTrue(self.business.is_verified)


class SubscriptionsAPITests(TestCase):
    """Test suite for Subscriptions & Checkout REST API."""

    def setUp(self):
        self.client = APIClient()
        seed_default_plans()
        self.user = User.objects.create_user(
            username='apiuser2@example.com',
            email='apiuser2@example.com',
            password='TestPassword@123'
        )
        self.client.force_authenticate(user=self.user)

    def test_api_plans_list(self):
        """GET /api/subscriptions/plans/ lists pricing tiers."""
        self.client.logout()  # Open to public
        resp = self.client.get(reverse('api_subscription_plans'))
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        results = resp.data.get('results', resp.data)
        self.assertEqual(len(results), 4)

    def test_api_current_subscription(self):
        """GET /api/subscriptions/current/ returns user's active plan."""
        resp = self.client.get(reverse('api_subscription_current'))
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['plan']['code'], 'free')

    def test_api_create_order_and_verify(self):
        """POST /api/subscriptions/create-order/ and POST /api/subscriptions/verify-payment/."""
        # Create order
        order_resp = self.client.post(reverse('api_create_razorpay_order'), {'plan_code': 'premium_event'})
        self.assertEqual(order_resp.status_code, status.HTTP_200_OK)
        self.assertIn('order_id', order_resp.data)

        # Verify payment
        verify_resp = self.client.post(reverse('api_verify_payment'), {
            'razorpay_order_id': order_resp.data['order_id'],
            'razorpay_payment_id': 'pay_api_verified_999',
            'razorpay_signature': 'sig_api_valid'
        })
        self.assertEqual(verify_resp.status_code, status.HTTP_200_OK)
        self.assertTrue(verify_resp.data['success'])
        self.user.refresh_from_db()
        self.assertTrue(self.user.is_premium)
