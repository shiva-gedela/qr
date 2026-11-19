"""
apps/core/sitemaps.py

Dynamic XML Sitemaps for QRouteX search engine discovery.
Covers:
- Static public views (Home, Events, Business Directory, Pricing, About)
- Public Events (published, non-password protected)
- Active Business & Vendor Listings
- Location-based City Landing Pages (Hyderabad, Bengaluru, etc.)
"""

from django.contrib.sitemaps import Sitemap
from django.urls import reverse
from apps.events.models import Event
from apps.business.models import Business


class StaticViewSitemap(Sitemap):
    """Sitemap for top-level static marketing and listing pages."""
    priority = 0.8
    changefreq = 'daily'
    protocol = 'https'

    def items(self):
        return ['home', 'event_list', 'business_list', 'pricing', 'about']

    def location(self, item):
        return reverse(item)


class EventSitemap(Sitemap):
    """Sitemap for all public, indexable events."""
    priority = 0.9
    changefreq = 'daily'
    protocol = 'https'

    def items(self):
        return Event.objects.filter(is_published=True, is_private=False).order_by('-updated_at')

    def lastmod(self, obj):
        return obj.updated_at

    def location(self, obj):
        return obj.get_absolute_url()


class BusinessSitemap(Sitemap):
    """Sitemap for all active verified digital business & vendor profiles."""
    priority = 0.85
    changefreq = 'weekly'
    protocol = 'https'

    def items(self):
        return Business.objects.filter(is_active=True).order_by('-updated_at')

    def lastmod(self, obj):
        return obj.updated_at

    def location(self, obj):
        return obj.get_absolute_url()


class CitySitemap(Sitemap):
    """Sitemap for local city SEO landing pages (e.g. Hyderabad, Bengaluru)."""
    priority = 0.8
    changefreq = 'weekly'
    protocol = 'https'

    cities = [
        'hyderabad',
        'bengaluru',
        'mumbai',
        'delhi',
        'chennai',
        'pune',
        'kolkata',
        'ahmedabad',
        'jaipur',
        'chandigarh',
        'kochi',
        'visakhapatnam',
    ]

    def items(self):
        return self.cities

    def location(self, item):
        return f'/city/{item}/'
