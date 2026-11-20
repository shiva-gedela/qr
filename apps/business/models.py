"""
apps/business/models.py

Normalized models for Digital Business Profiles and Products/Services.
Tables:
 - businesses
 - business_services
"""

import uuid
import re
from django.db import models
from django.conf import settings
from django.utils.text import slugify
from django.urls import reverse


class Business(models.Model):
    """
    Digital Business Profile model.
    Powers digital business cards, interactive action buttons (Call, WhatsApp,
    Directions, Email), products/services catalog, and branded QR codes.
    """

    BUSINESS_CATEGORIES = [
        ('retail', 'Retail & Shopping'),
        ('food', 'Restaurant, Cafe & Catering'),
        ('event_services', 'Event Planning & Decoration'),
        ('photography', 'Photography & Videography'),
        ('beauty', 'Salon, Spa & Beauty'),
        ('health', 'Healthcare & Wellness'),
        ('tech', 'Technology & IT Services'),
        ('education', 'Education & Coaching'),
        ('real_estate', 'Real Estate & Construction'),
        ('automotive', 'Automotive & Rentals'),
        ('consulting', 'Professional Consulting & Legal'),
        ('other', 'Other Business'),
    ]

    id = models.BigAutoField(primary_key=True)
    uuid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='businesses'
    )

    # Core Branding
    name = models.CharField(max_length=200)
    slug = models.SlugField(max_length=220, unique=True, blank=True)
    tagline = models.CharField(max_length=250, blank=True, help_text="Short subtitle or slogan")
    category = models.CharField(max_length=40, choices=BUSINESS_CATEGORIES, default='other')
    description = models.TextField(blank=True, help_text="Full business overview, about us, specialties")

    logo = models.ImageField(upload_to='businesses/logos/', blank=True, null=True)
    cover_image = models.ImageField(upload_to='businesses/covers/', blank=True, null=True)

    # Contact & Quick Action Channels
    phone = models.CharField(max_length=30, blank=True)
    whatsapp = models.CharField(max_length=30, blank=True, help_text="WhatsApp phone with country code e.g. +919876543210")
    email = models.EmailField(blank=True)
    website = models.URLField(blank=True, help_text="Official website URL")

    # Social Channels
    instagram = models.CharField(max_length=150, blank=True, help_text="Instagram profile URL or handle")
    facebook = models.URLField(blank=True, help_text="Facebook page URL")
    twitter = models.CharField(max_length=150, blank=True, help_text="Twitter / X profile URL or handle")
    linkedin = models.URLField(blank=True, help_text="LinkedIn business URL")
    youtube = models.URLField(blank=True, help_text="YouTube channel URL")

    # Location & Physical Address
    address = models.TextField(blank=True)
    city = models.CharField(max_length=100, blank=True)
    state = models.CharField(max_length=100, blank=True)
    pincode = models.CharField(max_length=20, blank=True)
    maps_url = models.URLField(blank=True, help_text="Google Maps Directions URL")

    # Working Hours (e.g. Mon - Sat: 9:00 AM - 8:00 PM)
    working_hours = models.TextField(
        blank=True,
        default="Monday - Saturday: 9:00 AM - 8:00 PM\nSunday: Closed",
        help_text="Operating hours line by line"
    )

    # Status
    is_active = models.BooleanField(default=True)
    is_verified = models.BooleanField(default=False)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'businesses'
        verbose_name = 'Business Profile'
        verbose_name_plural = 'Business Profiles'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['owner', 'is_active']),
            models.Index(fields=['slug']),
            models.Index(fields=['uuid']),
            models.Index(fields=['category']),
        ]

    def __str__(self):
        return f"{self.name} ({self.get_category_display()})"

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = self._generate_unique_slug()
        super().save(*args, **kwargs)

    def _generate_unique_slug(self):
        base_slug = slugify(self.name)[:180] or f"business-{uuid.uuid4().hex[:8]}"
        slug = base_slug
        counter = 1
        while Business.objects.filter(slug=slug).exists():
            slug = f"{base_slug}-{counter}"
            counter += 1
        return slug

    def get_absolute_url(self):
        return reverse('business_public', kwargs={'slug': self.slug})

    @property
    def logo_url(self):
        if self.logo:
            return self.logo.url
        return '/static/images/default-business-logo.png'

    @property
    def cover_image_url(self):
        if self.cover_image:
            return self.cover_image.url
        return '/static/images/default-business-cover.jpg'

    @property
    def clean_whatsapp_number(self):
        """Sanitize phone number for wa.me links."""
        digits = re.sub(r'\D', '', self.whatsapp or self.phone or '')
        return digits

    @property
    def whatsapp_url(self):
        num = self.clean_whatsapp_number
        if num:
            msg = f"Hello {self.name}, I found your profile on QRouteX (qroutex.com)."
            import urllib.parse
            return f"https://wa.me/{num}?text={urllib.parse.quote(msg)}"
        return ''

    @property
    def phone_url(self):
        clean = re.sub(r'[^\d+]', '', self.phone or '')
        return f"tel:{clean}" if clean else ''

    @property
    def full_address(self):
        parts = [self.address, self.city, self.state, self.pincode]
        return ", ".join([p.strip() for p in parts if p and p.strip()])

    def get_active_services(self):
        return self.services.filter(is_available=True).order_by('order', 'name')

    def generate_vcard_string(self):
        """Generates a standard vCard 3.0 contact string for instant mobile saving."""
        lines = [
            "BEGIN:VCARD",
            "VERSION:3.0",
            f"FN:{self.name}",
            f"ORG:{self.name}",
        ]
        if self.tagline:
            lines.append(f"TITLE:{self.tagline}")
        if self.phone:
            lines.append(f"TEL;TYPE=WORK,VOICE:{self.phone}")
        if self.whatsapp and self.whatsapp != self.phone:
            lines.append(f"TEL;TYPE=CELL,WHATSAPP:{self.whatsapp}")
        if self.email:
            lines.append(f"EMAIL;TYPE=PREF,INTERNET:{self.email}")
        if self.website:
            lines.append(f"URL:{self.website}")
        if self.full_address:
            lines.append(f"ADR;TYPE=WORK:;;{self.address};{self.city};{self.state};{self.pincode};")
        if self.description:
            clean_desc = self.description.replace('\n', ' ')[:200]
            lines.append(f"NOTE:{clean_desc}")
        lines.append(f"URL;TYPE=PROFILE:{settings.SITE_URL}/b/{self.slug}/")
        lines.append("END:VCARD")
        return "\r\n".join(lines)


class BusinessService(models.Model):
    """Products and Services catalog items offered by a Business."""

    PRICE_TYPES = [
        ('fixed', 'Fixed Price'),
        ('starting', 'Starting From'),
        ('hourly', 'Hourly Rate'),
        ('contact', 'Price on Request'),
    ]

    id = models.BigAutoField(primary_key=True)
    business = models.ForeignKey(
        Business,
        on_delete=models.CASCADE,
        related_name='services'
    )

    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    price_type = models.CharField(max_length=20, choices=PRICE_TYPES, default='fixed')
    image = models.ImageField(upload_to='businesses/services/', blank=True, null=True)

    order = models.PositiveIntegerField(default=0)
    is_available = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'business_services'
        verbose_name = 'Product / Service'
        verbose_name_plural = 'Products & Services'
        ordering = ['order', 'name']
        indexes = [
            models.Index(fields=['business', 'is_available']),
        ]

    def __str__(self):
        return f"{self.name} - {self.business.name}"

    @property
    def price_display(self):
        if self.price_type == 'contact' or self.price is None:
            return "Price on Request"
        if self.price_type == 'starting':
            return f"From ₹{self.price:,.2f}"
        if self.price_type == 'hourly':
            return f"₹{self.price:,.2f} / hr"
        return f"₹{self.price:,.2f}"

    @property
    def image_url(self):
        if self.image:
            return self.image.url
        return ''


class BusinessBooking(models.Model):
    """
    Table reservations and business service appointments.
    Synchronized between QRouteX web portals and mobile Flutter apps.
    """
    STATUS_CHOICES = [
        ('pending', 'Pending Approval'),
        ('confirmed', 'Confirmed'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
        ('rescheduled', 'Rescheduled'),
    ]

    id = models.BigAutoField(primary_key=True)
    booking_code = models.CharField(max_length=40, unique=True, blank=True)
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name='bookings')
    service = models.ForeignKey(BusinessService, on_delete=models.SET_NULL, null=True, blank=True, related_name='bookings')
    service_name = models.CharField(max_length=200, blank=True)
    service_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    customer_user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='customer_bookings')
    customer_name = models.CharField(max_length=150)
    customer_phone = models.CharField(max_length=30)
    customer_email = models.EmailField(blank=True)

    date = models.DateField(help_text="Booking or reservation date")
    time_slot = models.CharField(max_length=50, help_text="e.g. 07:00 PM - 08:30 PM")
    guests_count = models.PositiveIntegerField(default=2, help_text="Party size or guest count")
    special_requests = models.TextField(blank=True, help_text="Dietary needs, table preference, notes")
    status = models.CharField(max_length=25, choices=STATUS_CHOICES, default='confirmed')

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'business_bookings'
        verbose_name = 'Business Booking & Reservation'
        verbose_name_plural = 'Business Bookings & Reservations'
        ordering = ['-date', '-created_at']
        indexes = [
            models.Index(fields=['business', 'date']),
            models.Index(fields=['customer_phone', 'date']),
            models.Index(fields=['booking_code']),
            models.Index(fields=['status']),
        ]

    def save(self, *args, **kwargs):
        if not self.booking_code:
            import time, random
            self.booking_code = f"QX-BK{int(time.time()) % 1000000:06d}{random.randint(10, 99)}"
        if self.service and not self.service_name:
            self.service_name = self.service.name
        if self.service and self.service.price and self.service_price is None:
            self.service_price = self.service.price
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.booking_code}: {self.customer_name} @ {self.business.name} ({self.date})"

