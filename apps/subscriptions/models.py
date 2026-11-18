"""
apps/subscriptions/models.py

Normalized models for Subscriptions, Plans, Razorpay Payments, and Audit Logs.
Tables:
 - subscription_plans
 - subscriptions
 - payments
 - audit_logs
"""

import uuid
import io
from datetime import timedelta
from django.db import models
from django.conf import settings
from django.utils import timezone
from django.urls import reverse

from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors


class SubscriptionPlan(models.Model):
    """
    Tiered subscription plan definition.
    Four core plans:
    1. Free Plan
    2. Premium Event Website Plan
    3. Wedding Package
    4. Business Annual Subscription
    """

    PLAN_CODES = [
        ('free', 'Free Plan'),
        ('premium_event', 'Premium Event Website Plan'),
        ('wedding_package', 'Wedding Package'),
        ('business_annual', 'Business Annual Subscription'),
    ]

    id = models.BigAutoField(primary_key=True)
    code = models.CharField(max_length=50, unique=True, choices=PLAN_CODES)
    name = models.CharField(max_length=120)
    badge = models.CharField(max_length=50, blank=True, help_text="e.g. POPULAR, BEST VALUE")
    description = models.TextField(help_text="Summary of plan benefits")
    price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    duration_days = models.PositiveIntegerField(default=0, help_text="Duration in days (0 = lifetime)")

    # Entitlements & Feature Flags
    max_events = models.PositiveIntegerField(default=1)
    max_storage_mb = models.PositiveIntegerField(default=50)
    custom_qr_allowed = models.BooleanField(default=False)
    guest_upload_allowed = models.BooleanField(default=False)
    business_profile_allowed = models.BooleanField(default=False)
    tabletop_standee_pdf = models.BooleanField(default=False)
    remove_branding = models.BooleanField(default=False)

    order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'subscription_plans'
        verbose_name = 'Subscription Plan'
        verbose_name_plural = 'Subscription Plans'
        ordering = ['order', 'price']

    def __str__(self):
        return f"{self.name} - ₹{self.price:,.2f}"

    @property
    def is_free(self):
        return self.price <= 0

    @property
    def price_in_paise(self):
        """Razorpay expects amounts in integer paise (1 INR = 100 paise)."""
        return int(self.price * 100)


class Subscription(models.Model):
    """
    Active or historical user subscription record.
    """

    STATUS_CHOICES = [
        ('active', 'Active'),
        ('expired', 'Expired'),
        ('cancelled', 'Cancelled'),
        ('pending', 'Pending Payment'),
    ]

    id = models.BigAutoField(primary_key=True)
    uuid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='subscriptions'
    )
    plan = models.ForeignKey(
        SubscriptionPlan,
        on_delete=models.PROTECT,
        related_name='user_subscriptions'
    )

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    start_date = models.DateTimeField(default=timezone.now)
    end_date = models.DateTimeField(null=True, blank=True, help_text="Null for lifetime free plan")
    auto_renew = models.BooleanField(default=False)
    razorpay_subscription_id = models.CharField(max_length=100, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'subscriptions'
        verbose_name = 'User Subscription'
        verbose_name_plural = 'User Subscriptions'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['plan', 'status']),
            models.Index(fields=['end_date']),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.plan.name} ({self.status})"

    def is_valid(self):
        """Check if subscription is currently active and within expiry."""
        if self.status != 'active':
            return False
        if self.end_date and self.end_date < timezone.now():
            return False
        return True

    @property
    def days_remaining(self):
        if not self.end_date:
            return 9999  # Lifetime
        diff = (self.end_date - timezone.now()).days
        return max(0, diff)


class Payment(models.Model):
    """
    Financial transaction log for Razorpay charges and tax invoices.
    """

    STATUS_CHOICES = [
        ('created', 'Order Created'),
        ('authorized', 'Authorized'),
        ('captured', 'Captured (Success)'),
        ('failed', 'Failed'),
        ('refunded', 'Refunded'),
    ]

    id = models.BigAutoField(primary_key=True)
    uuid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='payments'
    )
    subscription = models.ForeignKey(
        Subscription,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='payments'
    )
    plan = models.ForeignKey(
        SubscriptionPlan,
        on_delete=models.PROTECT,
        related_name='payments'
    )

    invoice_number = models.CharField(max_length=60, unique=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    tax_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    currency = models.CharField(max_length=10, default='INR')

    razorpay_order_id = models.CharField(max_length=100, unique=True)
    razorpay_payment_id = models.CharField(max_length=100, blank=True)
    razorpay_signature = models.CharField(max_length=255, blank=True)

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='created')
    notes = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'payments'
        verbose_name = 'Payment Record'
        verbose_name_plural = 'Payment Records'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['razorpay_order_id']),
            models.Index(fields=['invoice_number']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self):
        return f"Invoice {self.invoice_number} - {self.user.email} - ₹{self.amount} ({self.status})"

    @classmethod
    def generate_invoice_number(cls):
        """Generates sequential invoice numbers like INV-202611-0001."""
        now = timezone.now()
        prefix = f"INV-{now.strftime('%Y%m')}"
        latest = cls.objects.filter(invoice_number__startswith=prefix).order_by('-invoice_number').first()
        if latest:
            try:
                seq = int(latest.invoice_number.split('-')[-1]) + 1
            except ValueError:
                seq = 1
        else:
            seq = 1
        return f"{prefix}-{seq:04d}"

    def generate_invoice_pdf(self):
        """Generates a professional tax invoice PDF using ReportLab."""
        buf = io.BytesIO()
        doc = SimpleDocTemplate(
            buf,
            pagesize=letter,
            rightMargin=40,
            leftMargin=40,
            topMargin=40,
            bottomMargin=40
        )
        styles = getSampleStyleSheet()
        elements = []

        # Header Title
        title_style = ParagraphStyle(
            'InvTitle',
            parent=styles['Heading1'],
            fontSize=22,
            leading=26,
            textColor=colors.HexColor('#1e293b')
        )
        elements.append(Paragraph(f"<b>QRouteX (qroutex.com)</b> - Tax Invoice", title_style))
        elements.append(Spacer(1, 10))

        # Invoice Metadata & Billed To
        user_name = self.user.get_full_name() or self.user.email
        info_data = [
            [
                Paragraph(f"<b>Invoice #:</b> {self.invoice_number}<br/>"
                          f"<b>Date:</b> {self.created_at.strftime('%d %B %Y')}<br/>"
                          f"<b>Payment ID:</b> {self.razorpay_payment_id or 'Pending'}<br/>"
                          f"<b>Status:</b> {self.get_status_display().upper()}", styles['Normal']),
                Paragraph(f"<b>Billed To:</b><br/>"
                          f"{user_name}<br/>"
                          f"Email: {self.user.email}<br/>"
                          f"Order ID: {self.razorpay_order_id}", styles['Normal'])
            ]
        ]
        info_table = Table(info_data, colWidths=[260, 260])
        info_table.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#f8fafc')),
            ('PADDING', (0,0), (-1,-1), 10),
            ('VALIGN', (0,0), (-1,-1), 'TOP'),
            ('LINEBELOW', (0,0), (-1,-1), 1, colors.HexColor('#e2e8f0')),
        ]))
        elements.append(info_table)
        elements.append(Spacer(1, 20))

        # Line Items Table
        subtotal = float(self.amount)
        item_data = [
            [Paragraph("<b>Item Description</b>", styles['Normal']),
             Paragraph("<b>Duration</b>", styles['Normal']),
             Paragraph("<b>Amount (INR)</b>", styles['Normal'])],
            [
                Paragraph(f"<b>{self.plan.name}</b><br/><font size=8 color='#64748b'>{self.plan.description}</font>", styles['Normal']),
                Paragraph(f"{self.plan.duration_days} Days" if self.plan.duration_days else "Lifetime Access", styles['Normal']),
                Paragraph(f"₹{subtotal:,.2f}", styles['Normal'])
            ],
            ["", Paragraph("<b>Total Paid:</b>", styles['Normal']), Paragraph(f"<b>₹{subtotal:,.2f}</b>", styles['Normal'])],
        ]
        item_table = Table(item_data, colWidths=[320, 100, 100])
        item_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#4f46e5')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('ALIGN', (1, 0), (-1, -1), 'RIGHT'),
            ('PADDING', (0, 0), (-1, -1), 8),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#cbd5e1')),
            ('BACKGROUND', (0, -1), (-1, -1), colors.HexColor('#f1f5f9')),
        ]))
        elements.append(item_table)
        elements.append(Spacer(1, 30))

        # Footer notes
        footer_style = ParagraphStyle('FooterNote', parent=styles['Normal'], fontSize=9, textColor=colors.HexColor('#64748b'))
        elements.append(Paragraph("Thank you for choosing QRouteX! For billing inquiries or GST support, contact billing@qroutex.com • https://qroutex.com", footer_style))

        doc.build(elements)
        buf.seek(0)
        return buf


class AuditLog(models.Model):
    """
    Audit log table for administrative actions, user security events,
    media approvals/rejections, and payment tracking.
    """

    ACTION_CHOICES = [
        ('USER_REGISTER', 'User Registration'),
        ('USER_LOGIN', 'User Login'),
        ('USER_BLOCK', 'User Blocked / Deactivated'),
        ('USER_UNBLOCK', 'User Unblocked / Activated'),
        ('EVENT_CREATE', 'Event Created'),
        ('EVENT_DELETE', 'Event Deleted'),
        ('MEDIA_APPROVE', 'Media Approved'),
        ('MEDIA_REJECT', 'Media Rejected'),
        ('BUSINESS_VERIFY', 'Business Verified'),
        ('SUBSCRIPTION_UPGRADE', 'Subscription Upgraded'),
        ('PAYMENT_SUCCESS', 'Payment Succeeded'),
        ('PAYMENT_FAILED', 'Payment Failed'),
    ]

    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='audit_logs'
    )
    action = models.CharField(max_length=60, choices=ACTION_CHOICES)
    resource_type = models.CharField(max_length=50, blank=True)
    resource_id = models.CharField(max_length=100, blank=True)
    ip_address = models.CharField(max_length=50, blank=True)
    details = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'audit_logs'
        verbose_name = 'Audit Log'
        verbose_name_plural = 'Audit Logs'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['action', 'created_at']),
            models.Index(fields=['resource_type', 'resource_id']),
            models.Index(fields=['user', 'created_at']),
        ]

    def __str__(self):
        user_str = self.user.email if self.user else "System"
        return f"[{self.created_at.strftime('%Y-%m-%d %H:%M')}] {user_str} - {self.action}"
