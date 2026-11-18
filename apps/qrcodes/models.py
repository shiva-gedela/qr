"""
apps/qrcodes/models.py

Normalized QRCode model for Events and Digital Business Profiles.
Table name: qr_codes
"""

import uuid
from django.db import models
from django.urls import reverse
from django.conf import settings


class QRCode(models.Model):
    """
    Unique QR code record attached to an Event or Business Profile.
    Preserves scan metrics, custom branding (fill/background colors, center logo),
    and points directly to public mini-websites or via trackable scan endpoints.
    """

    QR_TYPES = [
        ('event', 'Event Invitation'),
        ('business', 'Business Profile'),
    ]

    id = models.BigAutoField(primary_key=True)
    uuid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    qr_type = models.CharField(max_length=20, choices=QR_TYPES, default='event')

    # Relations (nullable to accommodate event or business)
    event = models.OneToOneField(
        'events.Event',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='qr_code'
    )
    business = models.OneToOneField(
        'business.Business',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='qr_code'
    )
    invitation = models.OneToOneField(
        'events.Invitation',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='qr_code'
    )

    target_url = models.URLField(max_length=500, help_text="Destination URL opened when QR is scanned")

    # Custom styling
    fill_color = models.CharField(max_length=20, default='#000000', help_text="Hex color code for QR code foreground")
    back_color = models.CharField(max_length=20, default='#FFFFFF', help_text="Hex color code for QR code background")
    logo = models.ImageField(upload_to='qrcodes/logos/', blank=True, null=True, help_text="Center icon/logo on QR code")
    qr_image = models.ImageField(upload_to='qrcodes/images/', blank=True, null=True)

    # Analytics
    scan_count = models.PositiveIntegerField(default=0, help_text="Total times this QR code has been scanned")
    last_scanned_at = models.DateTimeField(null=True, blank=True)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'qr_codes'
        verbose_name = 'QR Code'
        verbose_name_plural = 'QR Codes'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['uuid']),
            models.Index(fields=['qr_type']),
            models.Index(fields=['event']),
            models.Index(fields=['business']),
        ]

    def __str__(self):
        if self.event:
            target = self.event.title
        elif self.business:
            target = self.business.name
        else:
            target = self.target_url
        return f"QR [{self.get_qr_type_display()}]: {target}"

    @property
    def image_url(self):
        if self.qr_image:
            return self.qr_image.url
        return ''

    def get_scan_url(self):
        """Trackable redirect URL for scanning."""
        return reverse('qr_scan_redirect', kwargs={'qr_uuid': self.uuid})

    def get_download_png_url(self):
        return reverse('qr_download_png', kwargs={'qr_uuid': self.uuid})

    def get_download_pdf_url(self):
        return reverse('qr_download_pdf', kwargs={'qr_uuid': self.uuid})
