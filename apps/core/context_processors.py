"""
apps/core/context_processors.py

Inject site-wide settings into every template context automatically.
"""

from django.conf import settings


def site_settings(request):
    """Make site name and URL available in all templates."""
    return {
        'SITE_NAME': getattr(settings, 'SITE_NAME', 'QRouteX'),
        'SITE_DOMAIN': getattr(settings, 'SITE_DOMAIN', 'qroutex.com'),
        'SITE_URL': getattr(settings, 'SITE_URL', 'https://qroutex.com'),
        'GOOGLE_MAPS_API_KEY': settings.GOOGLE_MAPS_API_KEY,
    }
