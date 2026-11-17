"""
apps/core/context_processors.py

Inject site-wide settings into every template context automatically.
"""

from django.conf import settings


def site_settings(request):
    """Make site name and URL available in all templates."""
    return {
        'SITE_NAME': settings.SITE_NAME,
        'SITE_URL': settings.SITE_URL,
        'GOOGLE_MAPS_API_KEY': settings.GOOGLE_MAPS_API_KEY,
    }
