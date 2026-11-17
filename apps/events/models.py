"""
apps/events/models.py

Event, EventMedia models.
Events have a unique slug and public URL.
Media supports images and videos with gallery categories.
"""

from django.db import models
from django.conf import settings
from django.utils.text import slugify
from django.urls import reverse
import uuid
import os


class Event(models.Model):
    """Core event model for all types of celebrations."""

    EVENT_TYPES = [
        ('wedding', '💍 Wedding'),
        ('birthday', '🎂 Birthday'),
        ('engagement', '💑 Engagement'),
        ('anniversary', '❤️ Anniversary'),
        ('housewarming', '🏠 Housewarming'),
        ('graduation', '🎓 Graduation'),
        ('babyshower', '👶 Baby Shower'),
        ('corporate', '💼 Corporate'),
        ('other', '🎉 Other Occasion'),
    ]

    # Ownership & identity
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='events'
    )
    id = models.BigAutoField(primary_key=True)
    uuid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    slug = models.SlugField(max_length=200, unique=True, blank=True)

    # Event details
    event_type = models.CharField(max_length=30, choices=EVENT_TYPES, default='other')
    title = models.CharField(max_length=200)
    host_names = models.CharField(max_length=300, help_text="Names of hosts, e.g. 'Ram & Priya'")
    description = models.TextField(blank=True)

    # Date & Time
    event_date = models.DateField()
    event_time = models.TimeField(blank=True, null=True)
    event_end_date = models.DateField(blank=True, null=True)
    event_end_time = models.TimeField(blank=True, null=True)

    # Venue & GPS
    venue_name = models.CharField(max_length=300, blank=True)
    venue_address = models.TextField(blank=True)
    maps_url = models.URLField(blank=True, help_text="Google Maps URL for the venue")

    # Social Pages & Event Community
    instagram_url = models.URLField(blank=True, help_text="Instagram event profile or page URL")
    facebook_url = models.URLField(blank=True, help_text="Facebook event/group URL")
    youtube_url = models.URLField(blank=True, help_text="YouTube live stream URL for virtual guests")
    event_hashtag = models.CharField(max_length=100, blank=True, help_text="Event hashtag, e.g. #PriyaWedsRam")
    dress_code = models.CharField(max_length=150, blank=True, help_text="Dress code suggestion, e.g. Festive / Formal")

    # Media
    cover_image = models.ImageField(upload_to='events/covers/', blank=True, null=True)

    # Status & Gallery Settings
    is_published = models.BooleanField(default=False)
    is_private = models.BooleanField(default=False, help_text="If true, requires password to view")
    private_password = models.CharField(max_length=100, blank=True)
    allow_guest_uploads = models.BooleanField(default=True, help_text="Allow guests to upload media on public invitation")
    require_media_approval = models.BooleanField(default=True, help_text="Require host approval for guest uploaded media")
    max_storage_mb = models.PositiveIntegerField(default=250, help_text="Storage limit in megabytes")

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'events'
        ordering = ['-event_date', '-created_at']
        indexes = [
            models.Index(fields=['owner', 'is_published']),
            models.Index(fields=['slug']),
            models.Index(fields=['event_date']),
            models.Index(fields=['uuid']),
        ]

    def __str__(self):
        return f"{self.title} ({self.get_event_type_display()}) - {self.event_date}"

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = self._generate_unique_slug()
        super().save(*args, **kwargs)

    def _generate_unique_slug(self):
        base_slug = slugify(f"{self.title}-{self.host_names}")[:180]
        slug = base_slug
        counter = 1
        while Event.objects.filter(slug=slug).exists():
            slug = f"{base_slug}-{counter}"
            counter += 1
        return slug

    def get_absolute_url(self):
        return reverse('event_public', kwargs={'slug': self.slug})

    @property
    def cover_image_url(self):
        if self.cover_image:
            return self.cover_image.url
        return '/static/images/default-event-cover.jpg'

    @property
    def event_type_icon(self):
        icons = {
            'wedding': '💍',
            'birthday': '🎂',
            'engagement': '💑',
            'anniversary': '❤️',
            'housewarming': '🏠',
            'graduation': '🎓',
            'babyshower': '👶',
            'corporate': '💼',
            'other': '🎉',
        }
        return icons.get(self.event_type, '🎉')

    @property
    def google_maps_directions_url(self):
        """Turn-by-turn Google Maps GPS navigation destination URL."""
        if self.maps_url and 'http' in self.maps_url:
            return self.maps_url
        import urllib.parse
        destination = f"{self.venue_name} {self.venue_address}".strip()
        if destination:
            encoded = urllib.parse.quote_plus(destination)
            return f"https://www.google.com/maps/dir/?api=1&destination={encoded}"
        return "https://maps.google.com/"

    def get_photos(self, category=None):
        qs = self.media.filter(media_type='image', is_approved=True)
        if category and category != 'all':
            qs = qs.filter(category=category)
        return qs.order_by('order', '-uploaded_at')

    def get_videos(self, category=None):
        qs = self.media.filter(media_type='video', is_approved=True)
        if category and category != 'all':
            qs = qs.filter(category=category)
        return qs.order_by('order', '-uploaded_at')

    def get_pending_media(self):
        return self.media.filter(is_approved=False).order_by('-uploaded_at')

    def get_used_storage_bytes(self):
        total = self.media.aggregate(total=models.Sum('file_size'))['total'] or 0
        return total

    @property
    def used_storage_mb(self):
        return round(self.get_used_storage_bytes() / (1024 * 1024), 2)

    @property
    def storage_percentage(self):
        max_bytes = self.max_storage_mb * 1024 * 1024
        if max_bytes == 0:
            return 0
        return min(100, round((self.get_used_storage_bytes() / max_bytes) * 100, 1))

    @property
    def is_storage_full(self):
        return self.get_used_storage_bytes() >= (self.max_storage_mb * 1024 * 1024)

    def get_categories_with_counts(self):
        """Returns categories and count of approved photos/videos in each."""
        counts = {}
        for item in self.media.filter(is_approved=True).values('category').annotate(count=models.Count('id')):
            counts[item['category']] = item['count']

        result = []
        for code, label in EventMedia.GALLERY_CATEGORIES:
            result.append({
                'code': code,
                'label': label,
                'count': counts.get(code, 0),
            })
        return result


def event_media_upload_path(instance, filename):
    """Dynamic upload path: events/<event_uuid>/<type>/<filename>"""
    ext = os.path.splitext(filename)[1].lower()
    new_name = f"{uuid.uuid4().hex}{ext}"
    return f"events/{instance.event.uuid}/{instance.media_type}s/{new_name}"


class EventMedia(models.Model):
    """Photo and video gallery items for an event."""

    MEDIA_TYPES = [
        ('image', 'Image'),
        ('video', 'Video'),
    ]

    GALLERY_CATEGORIES = [
        ('general', 'General'),
        ('ceremony', 'Ceremony'),
        ('reception', 'Reception'),
        ('decor', 'Decoration'),
        ('food', 'Food & Catering'),
        ('guests', 'Guests'),
        ('candid', 'Candid'),
        ('other', 'Other'),
    ]

    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='media')
    uploaded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True, related_name='uploaded_media'
    )
    media_type = models.CharField(max_length=10, choices=MEDIA_TYPES)
    file = models.FileField(upload_to=event_media_upload_path)
    thumbnail = models.ImageField(upload_to='events/thumbnails/', blank=True, null=True)
    caption = models.CharField(max_length=300, blank=True)
    category = models.CharField(max_length=30, choices=GALLERY_CATEGORIES, default='general')
    order = models.PositiveIntegerField(default=0)
    is_approved = models.BooleanField(default=True)
    is_public = models.BooleanField(default=True)
    file_size = models.PositiveBigIntegerField(default=0, help_text="Size in bytes")
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'event_media'
        ordering = ['order', '-uploaded_at']
        indexes = [
            models.Index(fields=['event', 'media_type', 'is_approved']),
        ]

    def __str__(self):
        return f"{self.get_media_type_display()} for {self.event.title}"

    @property
    def file_url(self):
        return self.file.url if self.file else ''

    @property
    def thumbnail_url(self):
        if self.thumbnail:
            return self.thumbnail.url
        if self.media_type == 'image' and self.file:
            return self.file.url
        return ''

    @property
    def file_size_mb(self):
        if self.file_size:
            return round(self.file_size / (1024 * 1024), 2)
        return 0

    def save(self, *args, **kwargs):
        # Auto-compute file size
        if self.file and not self.file_size:
            try:
                self.file_size = self.file.size
            except Exception:
                pass

        # Generate thumbnail for images
        if self.media_type == 'image' and self.file and not self.thumbnail:
            try:
                from PIL import Image
                import io
                from django.core.files.base import ContentFile

                self.file.seek(0)
                img = Image.open(self.file)
                if img.mode in ('RGBA', 'LA', 'P'):
                    bg = Image.new('RGB', img.size, (255, 255, 255))
                    if img.mode == 'P':
                        img = img.convert('RGBA')
                    bg.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
                    img = bg
                elif img.mode != 'RGB':
                    img = img.convert('RGB')

                img.thumbnail((500, 500), Image.Resampling.LANCZOS)
                thumb_io = io.BytesIO()
                img.save(thumb_io, format='JPEG', quality=85)
                thumb_io.seek(0)
                thumb_name = f"thumb_{os.path.splitext(os.path.basename(self.file.name))[0]}.jpg"
                self.thumbnail.save(thumb_name, ContentFile(thumb_io.getvalue()), save=False)
            except Exception:
                pass

        super().save(*args, **kwargs)
